///|
fn bad_report() -> @base.DiffError {
  @base.Failure({
    code: InvalidOptions,
    message: "Invalid MoonDiff JSON report",
    side: None,
    path: None,
    line: None,
    column: None,
  })
}

///|
fn read_report(text : String) -> @model.DiffReport raise @base.DiffError {
  // Reports can contain more than 100000 metadata nodes or 2 MiB of output.
  // Do not apply document limits to the output of a valid 10000-change analysis.
  let json = @input.parse_input(text) catch {
    error => {
      let spot = error.at()
      raise @base.Failure({
        code: ParseError,
        message: "Invalid report JSON",
        side: None,
        path: None,
        line: Some(spot.line),
        column: Some(spot.column),
      })
    }
  }
  let top = report_object(json)
  if report_string(report_field(top, "schema_version")) != "1.0" {
    raise bad_report()
  }
  if report_bool(report_field(top, "ok")) {
    report_fields(top, ["schema_version", "ok", "equal", "summary", "changes"])
    let fields = report_object(report_field(top, "summary"))
    report_fields(fields, [
      "added", "removed", "modified", "reordered", "ignored_subtrees",
    ])
    let summary : @model.Summary = {
      added: report_int(report_field(fields, "added"), 10000),
      removed: report_int(report_field(fields, "removed"), 10000),
      modified: report_int(report_field(fields, "modified"), 10000),
      reordered: report_int(report_field(fields, "reordered"), 10000),
      ignored_subtrees: report_int(
        report_field(fields, "ignored_subtrees"),
        100000,
      ),
    }
    let raw = report_array(report_field(top, "changes"))
    if raw.length() > 10000 {
      raise bad_report()
    }
    let changes = raw.map(read_change)
    let mut added = 0
    let mut removed = 0
    let mut modified = 0
    let mut reordered = 0
    for c in changes {
      match c.kind {
        Added => added += 1
        Removed => removed += 1
        Modified => modified += 1
        Reordered => reordered += 1
      }
    }
    if (added, removed, modified, reordered) !=
      (summary.added, summary.removed, summary.modified, summary.reordered) ||
      report_bool(report_field(top, "equal")) != changes.is_empty() {
      raise bad_report()
    }
    @model.Success(summary, changes)
  } else {
    report_fields(top, ["schema_version", "ok", "error"])
    let fields = report_object(report_field(top, "error"))
    report_fields(fields, ["code", "message", "side", "path", "line", "column"])
    let code = match report_string(report_field(fields, "code")) {
      "PARSE_ERROR" => @base.ParseError
      "DUPLICATE_KEY" => @base.DuplicateKey
      "INVALID_OPTIONS" => @base.InvalidOptions
      "INVALID_ARRAY_KEY" => @base.InvalidArrayKey
      "INPUT_LIMIT" => @base.InputLimit
      "DEPTH_LIMIT" => @base.DepthLimit
      "NODE_LIMIT" => @base.NodeLimit
      "CHANGE_LIMIT" => @base.ChangeLimit
      "NUMBER_LIMIT" => @base.NumberLimit
      "ENCODING_ERROR" => @base.EncodingError
      "IO_ERROR" => @base.IoError
      _ => raise bad_report()
    }
    let side = match report_nullable_string(report_field(fields, "side")) {
      None => None
      Some("old") => Some(@base.Old)
      Some("new") => Some(@base.New)
      Some("options") => Some(@base.Options)
      _ => raise bad_report()
    }
    @model.Error({
      code,
      message: report_string(report_field(fields, "message")),
      side,
      path: report_path(report_field(fields, "path")),
      line: report_coordinate(report_field(fields, "line")),
      column: report_coordinate(report_field(fields, "column")),
    })
  }
}

///|
fn report_object(value : Json) -> Map[String, Json] raise @base.DiffError {
  match value {
    Object(fields) => fields
    _ => raise bad_report()
  }
}

///|
fn report_array(value : Json) -> Array[Json] raise @base.DiffError {
  match value {
    Array(items) => items
    _ => raise bad_report()
  }
}

///|
fn report_field(
  fields : Map[String, Json],
  name : String,
) -> Json raise @base.DiffError {
  match fields.get(name) {
    Some(value) => value
    None => raise bad_report()
  }
}

///|
fn report_fields(
  fields : Map[String, Json],
  names : Array[String],
) -> Unit raise @base.DiffError {
  if fields.length() != names.length() {
    raise bad_report()
  }
  for name in names {
    if !fields.contains(name) {
      raise bad_report()
    }
  }
}

///|
fn report_string(value : Json) -> String raise @base.DiffError {
  match value {
    String(s) => s
    _ => raise bad_report()
  }
}

///|
fn report_bool(value : Json) -> Bool raise @base.DiffError {
  match value {
    True => true
    False => false
    _ => raise bad_report()
  }
}

///|
fn report_nullable_string(value : Json) -> String? raise @base.DiffError {
  match value {
    Null => None
    String(s) => Some(s)
    _ => raise bad_report()
  }
}

///|
fn report_int(value : Json, max : Int) -> Int raise @base.DiffError {
  let key = match value {
    Number(_, repr=Some(raw)) =>
      @model.normalize_number(raw) catch {
        @base.Failure(_) => raise bad_report()
      }
    _ => raise bad_report()
  }
  match key.bounded_int(max) {
    Some(n) => n
    None => raise bad_report()
  }
}

///|
fn report_coordinate(value : Json) -> Int? raise @base.DiffError {
  if value is Null {
    return None
  }
  let n = report_int(value, 2147483647)
  if n == 0 {
    raise bad_report()
  }
  Some(n)
}

///|
fn report_path(value : Json) -> String? raise @base.DiffError {
  let path = report_nullable_string(value)
  if path is Some(p) {
    let _ = @base.pointer_decode(p) catch {
      @base.Failure(_) => raise bad_report()
    }
  }
  path
}

///|
fn read_slot(value : Json) -> @model.ValueSlot raise @base.DiffError {
  let fields = report_object(value)
  report_fields(fields, ["present", "json_text"])
  let present = report_bool(report_field(fields, "present"))
  let text = report_nullable_string(report_field(fields, "json_text"))
  match (present, text) {
    (false, None) => @model.ValueSlot::absent()
    (true, Some(s)) => {
      let _ = @input.parse_document(s, @base.Options, @base.default_limits()) catch {
        @base.Failure(_) => raise bad_report()
      }
      @model.ValueSlot::present_json(s)
    }
    _ => raise bad_report()
  }
}

///|
fn read_identity(value : Json) -> @model.Identity? raise @base.DiffError {
  if value is Null {
    return None
  }
  let fields = report_object(value)
  report_fields(fields, [
    "array_old_path", "array_new_path", "key", "value_json",
  ])
  let old = report_path(report_field(fields, "array_old_path"))
  let new = report_path(report_field(fields, "array_new_path"))
  if old is None && new is None {
    raise bad_report()
  }
  let value_json = report_string(report_field(fields, "value_json"))
  let identity_value = @input.parse_document(
    value_json,
    @base.Options,
    @base.default_limits(),
  ) catch {
    @base.Failure(_) => raise bad_report()
  }
  match identity_value.root() {
    String(_) => ()
    Number(_, key) if key.is_integer() => ()
    _ => raise bad_report()
  }
  Some({
    array_old_path: old,
    array_new_path: new,
    key: report_string(report_field(fields, "key")),
    value_json,
  })
}

///|
fn read_change(value : Json) -> @model.Change raise @base.DiffError {
  let fields = report_object(value)
  report_fields(fields, [
    "kind", "old_path", "new_path", "before", "after", "identity",
  ])
  let kind = match report_string(report_field(fields, "kind")) {
    "added" => @model.Added
    "removed" => @model.Removed
    "modified" => @model.Modified
    "reordered" => @model.Reordered
    _ => raise bad_report()
  }
  let old = report_path(report_field(fields, "old_path"))
  let new = report_path(report_field(fields, "new_path"))
  let before = read_slot(report_field(fields, "before"))
  let after = read_slot(report_field(fields, "after"))
  let identity = read_identity(report_field(fields, "identity"))
  let valid = match kind {
    Added => old is None && new is Some(_) && !before.present && after.present
    Removed => old is Some(_) && new is None && before.present && !after.present
    Modified =>
      old is Some(_) && new is Some(_) && before.present && after.present
    Reordered =>
      old is Some(_) &&
      old == new &&
      before.present &&
      after.present &&
      identity is None
  }
  if !valid {
    raise bad_report()
  }
  { kind, old_path: old, new_path: new, before, after, identity, }
}
