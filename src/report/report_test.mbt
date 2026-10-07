///|
test "error JSON envelope is fixed and contains no success statistics" {
  let info : @base.ErrorInfo = {
    code: ChangeLimit,
    message: "too many",
    side: None,
    path: None,
    line: None,
    column: None,
  }
  assert_eq(
    @report.render_json(@model.Error(info)),
    "{\"schema_version\":\"1.0\",\"ok\":false,\"error\":{\"code\":\"CHANGE_LIMIT\",\"message\":\"too many\",\"side\":null,\"path\":null,\"line\":null,\"column\":null}}",
  )
  assert_eq(
    @report.render_text(@model.Error(info)),
    "error: CHANGE_LIMIT\nmessage: too many\nside: null path: null line: null column: null\n",
  )
}

///|
test "text format consumes valid reports and rejects malformed envelopes" {
  let equal = "{\"schema_version\":\"1.0\",\"ok\":true,\"equal\":true,\"summary\":{\"added\":0,\"removed\":0,\"modified\":0,\"reordered\":0,\"ignored_subtrees\":0},\"changes\":[]}"
  assert_eq(
    @report.format_text(equal),
    "equal: true\nadded: 0 removed: 0 modified: 0 reordered: 0 ignored_subtrees: 0\n",
  )
  for
    text in [
      "{}",
      "[]",
      "{\"ok\":true}",
      "{\"schema_version\":\"2.0\",\"ok\":false}",
      "{\"ok\":false,\"ok\":true}",
      equal + "x",
    ] {
    try @report.format_text(text) |> ignore catch {
      @base.Failure(_) => ()
    } noraise {
      _ => fail("invalid report formatted successfully")
    }
  }
}

///|
test "formatter rejects inconsistent counts slots pointers and embedded JSON" {
  let summary = "\"summary\":{\"added\":0,\"removed\":0,\"modified\":1,\"reordered\":0,\"ignored_subtrees\":0}"
  for
    change in [
      "{\"kind\":\"modified\",\"old_path\":\"/~2\",\"new_path\":\"\",\"before\":{\"present\":true,\"json_text\":\"0\"},\"after\":{\"present\":true,\"json_text\":\"1\"},\"identity\":null}",
      "{\"kind\":\"modified\",\"old_path\":\"\",\"new_path\":\"\",\"before\":{\"present\":false,\"json_text\":\"0\"},\"after\":{\"present\":true,\"json_text\":\"1\"},\"identity\":null}",
      "{\"kind\":\"modified\",\"old_path\":\"\",\"new_path\":\"\",\"before\":{\"present\":true,\"json_text\":\"not json\"},\"after\":{\"present\":true,\"json_text\":\"1\"},\"identity\":null}",
    ] {
    let text = "{\"schema_version\":\"1.0\",\"ok\":true,\"equal\":false," +
      summary +
      ",\"changes\":[" +
      change +
      "]}"
    try @report.format_text(text) |> ignore catch {
      @base.Failure(_) => ()
    } noraise {
      _ => fail("inconsistent report accepted")
    }
  }
  let counts = "{\"schema_version\":\"1.0\",\"ok\":true,\"equal\":false," +
    summary +
    ",\"changes\":[]}"
  try @report.format_text(counts) |> ignore catch {
    @base.Failure(_) => ()
  } noraise {
    _ => fail("wrong summary accepted")
  }
}
