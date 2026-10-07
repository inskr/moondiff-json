///|
test "ignore tokens do not match prefixes of member names" {
  let (s, c) = basic_result(
    "{\"meta\":1,\"metadata\":1}",
    "{\"meta\":2,\"metadata\":2}",
    ignoring(["/meta"]),
  )
  assert_eq(summary_counts(s), (0, 0, 1, 0, 1))
  assert_eq(change_rows(c), [
    (
      "modified",
      Some("/metadata"),
      Some("/metadata"),
      true,
      Some("1"),
      true,
      Some("2"),
    ),
  ])
}

///|
test "ignore skips added removed and type changing subtrees once" {
  let (s, c) = basic_result(
    "{\"gone\":{\"x\":1},\"type\":null}",
    "{\"new\":[1,2],\"type\":{\"x\":2}}",
    ignoring(["/gone", "/new", "/type"]),
  )
  assert_eq(summary_counts(s), (0, 0, 0, 0, 3))
  assert_eq(c.length(), 0)
}

///|
test "duplicates and parent child ignores count outermost compared node" {
  let (s, c) = basic_result(
    "{\"meta\":{\"x\":1,\"y\":2}}",
    "{\"meta\":{\"x\":3,\"y\":4}}",
    ignoring(["/meta/x", "/meta", "/meta", "/absent"]),
  )
  assert_eq(summary_counts(s), (0, 0, 0, 0, 1))
  assert_eq(c.length(), 0)
}

///|
test "ignore counts existing equal nodes but not absent paths" {
  let (s, _) = basic_result(
    "{\"meta\":null}",
    "{\"meta\":null}",
    ignoring(["/meta", "/missing/x"]),
  )
  assert_eq(summary_counts(s), (0, 0, 0, 0, 1))
}

///|
test "root ignore is rejected even with identical inputs" {
  assert_option_error("{}", "{}", ignoring([""]))
}

///|
test "ignore may target arrays but may never enter either side array" {
  let (s, _) = basic_result("{\"a\":[1]}", "{\"a\":[2]}", ignoring(["/a"]))
  assert_eq(summary_counts(s), (0, 0, 0, 0, 1))
  assert_option_error("{\"a\":[1]}", "{}", ignoring(["/a/0"]))
  assert_option_error("{}", "{\"a\":[2]}", ignoring(["/a/0"]))
  assert_option_error("[]", "{}", ignoring(["/missing"]))
}

///|
test "shadowed child ignore is still validated before parent skipping" {
  assert_option_error("{\"a\":[1]}", "{}", ignoring(["/a", "/a/0"]))
}

///|
test "ignore paths through scalars and missing prefixes do not match" {
  let (s, c) = basic_result(
    "{\"a\":1}",
    "{\"a\":2}",
    ignoring(["/a/x", "/missing/x"]),
  )
  assert_eq(summary_counts(s), (0, 0, 1, 0, 0))
  assert_eq(c.length(), 1)
}

///|
test "escaped ignore tokens match literal empty and slash keys" {
  let (s, _) = basic_result(
    "{\"\":{\"~/\":1}}",
    "{\"\":{\"~/\":2}}",
    ignoring(["//~0~1"]),
  )
  assert_eq(summary_counts(s), (0, 0, 0, 0, 1))
}

///|
test "unsupported keyed arrays never silently fall back to position" {
  let options = {
    ..@model.Options::default(),
    array_rules: [{ path: [], key: "id", check_order: false, }],
  }
  assert_option_error("[]", "[]", options)
}

///|
test "change limit accepts exact boundary and rejects overflow" {
  let options = {
    ..@model.Options::default(),
    limits: @model.Limits::new(max_changes=1),
  }
  let (s, _) = basic_result("[0]", "[1]", options)
  assert_eq(summary_counts(s), (0, 0, 1, 0, 0))
  try basic_result("[0,0]", "[1,1]", options) |> ignore catch {
    @base.Failure(info) => assert_eq(info.code, @base.ChangeLimit)
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("partial success returned after change limit")
  }
}
