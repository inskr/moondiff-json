///|
pub fn render_json(report : @model.DiffReport) -> String {
  let out = StringBuilder()
  out.write_string("{\"schema_version\":\"1.0\",\"ok\":")
  match report {
    Success(s, changes) => {
      out.write_string("true,\"equal\":")
      out.write_string(
        if s.added + s.removed + s.modified + s.reordered == 0 {
          "true"
        } else {
          "false"
        },
      )
      out.write_string(
        ",\"summary\":{\"added\":" +
        s.added.to_string() +
        ",\"removed\":" +
        s.removed.to_string() +
        ",\"modified\":" +
        s.modified.to_string() +
        ",\"reordered\":" +
        s.reordered.to_string() +
        ",\"ignored_subtrees\":" +
        s.ignored_subtrees.to_string() +
        "},\"changes\":[",
      )
      for i, change in changes {
        if i > 0 {
          out.write_char(',')
        }
        out.write_string(
          "{\"kind\":" +
          quote_string(kind_name(change.kind)) +
          ",\"old_path\":" +
          nullable_string(change.old_path) +
          ",\"new_path\":" +
          nullable_string(change.new_path) +
          ",\"before\":",
        )
        write_slot(out, change.before)
        out.write_string(",\"after\":")
        write_slot(out, change.after)
        out.write_string(",\"identity\":")
        match change.identity {
          None => out.write_string("null")
          Some(id) =>
            out.write_string(
              "{\"array_old_path\":" +
              nullable_string(id.array_old_path) +
              ",\"array_new_path\":" +
              nullable_string(id.array_new_path) +
              ",\"key\":" +
              quote_string(id.key) +
              ",\"value_json\":" +
              quote_string(id.value_json) +
              "}",
            )
        }
        out.write_char('}')
      }
      out.write_string("]}")
    }
    Error(info) =>
      out.write_string(
        "false,\"error\":{\"code\":" +
        quote_string(code_name(info.code)) +
        ",\"message\":" +
        quote_string(info.message) +
        ",\"side\":" +
        nullable_string(info.side.map(side_name)) +
        ",\"path\":" +
        nullable_string(info.path) +
        ",\"line\":" +
        nullable_int(info.line) +
        ",\"column\":" +
        nullable_int(info.column) +
        "}}",
      )
  }
  out.to_string()
}

///|
fn nullable_string(value : String?) -> String {
  match value {
    None => "null"
    Some(s) => quote_string(s)
  }
}

///|
fn nullable_int(value : Int?) -> String {
  match value {
    None => "null"
    Some(n) => n.to_string()
  }
}

///|
fn write_slot(out : StringBuilder, value : @model.ValueSlot) -> Unit {
  out.write_string(
    "{\"present\":" +
    (if value.present { "true" } else { "false" }) +
    ",\"json_text\":" +
    nullable_string(value.json_text) +
    "}",
  )
}

///|
fn kind_name(kind : @model.ChangeKind) -> String {
  match kind {
    Added => "added"
    Removed => "removed"
    Modified => "modified"
    Reordered => "reordered"
  }
}

///|
fn side_name(side : @base.Side) -> String {
  match side {
    Old => "old"
    New => "new"
    Options => "options"
  }
}

///|
fn code_name(code : @base.ErrorCode) -> String {
  match code {
    ParseError => "PARSE_ERROR"
    DuplicateKey => "DUPLICATE_KEY"
    InvalidOptions => "INVALID_OPTIONS"
    InvalidArrayKey => "INVALID_ARRAY_KEY"
    InputLimit => "INPUT_LIMIT"
    DepthLimit => "DEPTH_LIMIT"
    NodeLimit => "NODE_LIMIT"
    ChangeLimit => "CHANGE_LIMIT"
    NumberLimit => "NUMBER_LIMIT"
    EncodingError => "ENCODING_ERROR"
    IoError => "IO_ERROR"
  }
}
