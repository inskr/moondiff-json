///|
fn basic_result(
  old : String,
  new : String,
  options : @model.Options,
) -> (@model.Summary, Array[@model.Change]) raise {
  let old_doc = @model.parse_document(old, @base.Old, options.limits)
  let new_doc = @model.parse_document(new, @base.New, options.limits)
  match @diff.diff_documents(old_doc, new_doc, options) {
    @model.Success(summary, changes) => (summary, changes)
    @model.Error(_) => {
      fail("unexpected error report")
      abort("unreachable")
    }
  }
}

///|
fn summary_counts(s : @model.Summary) -> (Int, Int, Int, Int, Int) {
  (s.added, s.removed, s.modified, s.reordered, s.ignored_subtrees)
}

///|
fn change_rows(
  changes : Array[@model.Change],
) -> Array[(String, String?, String?, Bool, String?, Bool, String?)] {
  changes.map(c => {
    let kind = match c.kind {
      Added => "added"
      Removed => "removed"
      Modified => "modified"
      Reordered => "reordered"
    }
    (
      kind,
      c.old_path,
      c.new_path,
      c.before.present,
      c.before.json_text,
      c.after.present,
      c.after.json_text,
    )
  })
}

///|
fn ignoring(paths : Array[String]) -> @model.Options raise {
  {
    ..@model.Options::default(),
    ignore_paths: paths.map(p => @diff.pointer_decode(p)),
  }
}

///|
fn assert_option_error(
  old : String,
  new : String,
  options : @model.Options,
) -> Unit raise {
  try basic_result(old, new, options) |> ignore catch {
    @base.Failure(info) => {
      assert_eq(info.code, @base.InvalidOptions)
      assert_eq(info.side, Some(@base.Options))
    }
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("invalid configuration accepted")
  }
}
