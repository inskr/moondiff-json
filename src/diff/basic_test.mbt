// Generated from fixtures/basic/cases.json by scripts/generate-basic-tests.mjs.

///|
test "identical nested inputs" {
  let (summary, changes) = basic_result(
    "{\"a\":[null,true,{\"x\":1}]}",
    "{\"a\":[null,true,{\"x\":1}]}",
    @model.Options::default(),
  )
  assert_eq(summary_counts(summary), (0, 0, 0, 0, 0))
  assert_eq(change_rows(changes), [])
}

///|
test "object order and numeric notation are immaterial" {
  let (summary, changes) = basic_result(
    "{\"b\":2,\"aa\":1.0,\"a\":\"🌙\"}",
    "{\"a\":\"\\ud83c\\udf19\",\"aa\":1e0,\"b\":2}",
    @model.Options::default(),
  )
  assert_eq(summary_counts(summary), (0, 0, 0, 0, 0))
  assert_eq(change_rows(changes), [])
}

///|
test "fields use sorted depth first order and whole subtree slots" {
  let (summary, changes) = basic_result(
    "{\"b\":{\"z\":1},\"a\":{\"x\":1},\"gone\":[1,2]}",
    "{\"new\":{\"z\":9007199254740993,\"aa\":1e0,\"a\":null},\"b\":{\"z\":2},\"a\":{\"x\":2}}",
    @model.Options::default(),
  )
  assert_eq(summary_counts(summary), (1, 1, 2, 0, 0))
  assert_eq(change_rows(changes), [
    ("modified", Some("/a/x"), Some("/a/x"), true, Some("1"), true, Some("2")),
    ("modified", Some("/b/z"), Some("/b/z"), true, Some("1"), true, Some("2")),
    ("removed", Some("/gone"), None, true, Some("[1,2]"), false, None),
    (
      "added",
      None,
      Some("/new"),
      false,
      None,
      true,
      Some("{\"a\":null,\"aa\":1e0,\"z\":9007199254740993}"),
    ),
  ])
}

///|
test "null differs from missing on both sides" {
  let (summary, changes) = basic_result(
    "{\"a\":null}",
    "{\"b\":null}",
    @model.Options::default(),
  )
  assert_eq(summary_counts(summary), (1, 1, 0, 0, 0))
  assert_eq(change_rows(changes), [
    ("removed", Some("/a"), None, true, Some("null"), false, None),
    ("added", None, Some("/b"), false, None, true, Some("null")),
  ])
}

///|
test "type changes are one modification per subtree" {
  let (summary, changes) = basic_result(
    "{\"a\":{\"x\":[1]},\"b\":false,\"c\":1}",
    "{\"a\":[2,3],\"b\":0,\"c\":\"1\"}",
    @model.Options::default(),
  )
  assert_eq(summary_counts(summary), (0, 0, 3, 0, 0))
  assert_eq(change_rows(changes), [
    (
      "modified",
      Some("/a"),
      Some("/a"),
      true,
      Some("{\"x\":[1]}"),
      true,
      Some("[2,3]"),
    ),
    ("modified", Some("/b"), Some("/b"), true, Some("false"), true, Some("0")),
    ("modified", Some("/c"), Some("/c"), true, Some("1"), true, Some("\"1\"")),
  ])
}

///|
test "root scalar uses an empty path and exact large integer tokens" {
  let (summary, changes) = basic_result(
    "9007199254740992",
    "9007199254740993",
    @model.Options::default(),
  )
  assert_eq(summary_counts(summary), (0, 0, 1, 0, 0))
  assert_eq(change_rows(changes), [
    (
      "modified",
      Some(""),
      Some(""),
      true,
      Some("9007199254740992"),
      true,
      Some("9007199254740993"),
    ),
  ])
}

///|
test "zero and extreme decimal notation compare exactly" {
  let (summary, changes) = basic_result(
    "[0,1.20e2,1e-9999,10e10000]",
    "[-0.0,120,10e-10000,100e9999]",
    @model.Options::default(),
  )
  assert_eq(summary_counts(summary), (0, 0, 0, 0, 0))
  assert_eq(change_rows(changes), [])
}

///|
test "tiny decimal differences survive double underflow" {
  let (summary, changes) = basic_result(
    "1e-10000",
    "2e-10000",
    @model.Options::default(),
  )
  assert_eq(summary_counts(summary), (0, 0, 1, 0, 0))
  assert_eq(change_rows(changes), [
    (
      "modified",
      Some(""),
      Some(""),
      true,
      Some("1e-10000"),
      true,
      Some("2e-10000"),
    ),
  ])
}

///|
test "position insertion modifies shared indices then adds tail" {
  let (summary, changes) = basic_result(
    "[1,2,3]",
    "[1,9,2,3]",
    @model.Options::default(),
  )
  assert_eq(summary_counts(summary), (1, 0, 2, 0, 0))
  assert_eq(change_rows(changes), [
    ("modified", Some("/1"), Some("/1"), true, Some("2"), true, Some("9")),
    ("modified", Some("/2"), Some("/2"), true, Some("3"), true, Some("2")),
    ("added", None, Some("/3"), false, None, true, Some("3")),
  ])
}

///|
test "position deletion removes a whole tail value" {
  let (summary, changes) = basic_result(
    "[1,{\"x\":[2]}]",
    "[1]",
    @model.Options::default(),
  )
  assert_eq(summary_counts(summary), (0, 1, 0, 0, 0))
  assert_eq(change_rows(changes), [
    ("removed", Some("/1"), None, true, Some("{\"x\":[2]}"), false, None),
  ])
}

///|
test "empty containers of different types differ once" {
  let (summary, changes) = basic_result("{}", "[]", @model.Options::default())
  assert_eq(summary_counts(summary), (0, 0, 1, 0, 0))
  assert_eq(change_rows(changes), [
    ("modified", Some(""), Some(""), true, Some("{}"), true, Some("[]")),
  ])
}

///|
test "paths escape empty Chinese emoji and slash tilde keys" {
  let (summary, changes) = basic_result(
    "{\"\":{\"~/\":1},\"中文🌙\":true}",
    "{\"\":{\"~/\":2},\"中文🌙\":false}",
    @model.Options::default(),
  )
  assert_eq(summary_counts(summary), (0, 0, 2, 0, 0))
  assert_eq(change_rows(changes), [
    (
      "modified",
      Some("//~0~1"),
      Some("//~0~1"),
      true,
      Some("1"),
      true,
      Some("2"),
    ),
    (
      "modified",
      Some("/中文🌙"),
      Some("/中文🌙"),
      true,
      Some("true"),
      true,
      Some("false"),
    ),
  ])
}

///|
test "Unicode codepoint order differs from shortlex and UTF16" {
  let (summary, changes) = basic_result(
    "{}",
    "{\"🌙\":0,\"\":0,\"b\":0,\"aa\":0,\"a\":0}",
    @model.Options::default(),
  )
  assert_eq(summary_counts(summary), (5, 0, 0, 0, 0))
  assert_eq(change_rows(changes), [
    ("added", None, Some("/a"), false, None, true, Some("0")),
    ("added", None, Some("/aa"), false, None, true, Some("0")),
    ("added", None, Some("/b"), false, None, true, Some("0")),
    ("added", None, Some("/"), false, None, true, Some("0")),
    ("added", None, Some("/🌙"), false, None, true, Some("0")),
  ])
}

///|
test "whole fragments sort codepoints and preserve quoted string and numbers" {
  let (summary, changes) = basic_result(
    "null",
    "{\"🌙\":9007199254740993,\"\":1e400,\"b\":\"line\\nquote\\\"slash\\\\\",\"aa\":-0.0,\"a\":[]}",
    @model.Options::default(),
  )
  assert_eq(summary_counts(summary), (0, 0, 1, 0, 0))
  assert_eq(change_rows(changes), [
    (
      "modified",
      Some(""),
      Some(""),
      true,
      Some("null"),
      true,
      Some(
        "{\"a\":[],\"aa\":-0.0,\"b\":\"line\\nquote\\\"slash\\\\\",\"\":1e400,\"🌙\":9007199254740993}",
      ),
    ),
  ])
}

///|
test "decoded strings equal without Unicode normalization" {
  let (summary, changes) = basic_result(
    "[\"a\",\"é\"]",
    "[\"\\u0061\",\"é\"]",
    @model.Options::default(),
  )
  assert_eq(summary_counts(summary), (0, 0, 1, 0, 0))
  assert_eq(change_rows(changes), [
    (
      "modified",
      Some("/1"),
      Some("/1"),
      true,
      Some("\"é\""),
      true,
      Some("\"é\""),
    ),
  ])
}
