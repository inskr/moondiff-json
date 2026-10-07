///|
pub fn render_text(report : @model.DiffReport) -> String {
  let out = StringBuilder()
  match report {
    Error(info) =>
      out.write_string(
        "error: " +
        code_name(info.code) +
        "\nmessage: " +
        info.message +
        "\nside: " +
        nullable_string(info.side.map(side_name)) +
        " path: " +
        nullable_string(info.path) +
        " line: " +
        nullable_int(info.line) +
        " column: " +
        nullable_int(info.column) +
        "\n",
      )
    Success(s, changes) => {
      out.write_string(
        "equal: " +
        (if s.added + s.removed + s.modified + s.reordered == 0 {
          "true"
        } else {
          "false"
        }) +
        "\nadded: " +
        s.added.to_string() +
        " removed: " +
        s.removed.to_string() +
        " modified: " +
        s.modified.to_string() +
        " reordered: " +
        s.reordered.to_string() +
        " ignored_subtrees: " +
        s.ignored_subtrees.to_string() +
        "\n",
      )
      for change in changes {
        out.write_string(
          kind_name(change.kind) +
          " old=" +
          nullable_string(change.old_path) +
          " new=" +
          nullable_string(change.new_path) +
          "\n  before: " +
          (if change.before.present {
            change.before.json_text.unwrap()
          } else {
            "<absent>"
          }) +
          "\n  after: " +
          (if change.after.present {
            change.after.json_text.unwrap()
          } else {
            "<absent>"
          }) +
          "\n",
        )
        if change.identity is Some(id) {
          out.write_string(
            "  identity: array_old=" +
            nullable_string(id.array_old_path) +
            " array_new=" +
            nullable_string(id.array_new_path) +
            " key=" +
            quote_string(id.key) +
            " value=" +
            id.value_json +
            "\n",
          )
        }
      }
    }
  }
  out.to_string()
}

///|
pub fn format_text(text : String) -> String raise @base.DiffError {
  render_text(read_report(text))
}
