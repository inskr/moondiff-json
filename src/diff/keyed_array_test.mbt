// Generated from fixtures/keyed/cases.json by scripts/generate-keyed-tests.mjs.

///|
test "explicit keyed reorder is equal by default" {
  let (s, c) = basic_result(
    "{\"users\":[{\"id\":\"a\"},{\"id\":\"b\"}]}",
    "{\"users\":[{\"id\":\"b\"},{\"id\":\"a\"}]}",
    keyed_options("/users", "id", false),
  )
  assert_eq(summary_counts(s), (0, 0, 0, 0, 0))
  assert_eq(change_rows(c), [])
  assert_eq(identity_rows(c), [])
}

///|
test "checked reorder reports shared identity sequences" {
  let (s, c) = basic_result(
    "{\"users\":[{\"id\":\"a\"},{\"id\":\"b\"}]}",
    "{\"users\":[{\"id\":\"b\"},{\"id\":\"a\"}]}",
    keyed_options("/users", "id", true),
  )
  assert_eq(summary_counts(s), (0, 0, 0, 1, 0))
  assert_eq(change_rows(c), [
    (
      "reordered",
      Some("/users"),
      Some("/users"),
      true,
      Some("[\"a\",\"b\"]"),
      true,
      Some("[\"b\",\"a\"]"),
    ),
  ])
  assert_eq(identity_rows(c), [None])
}

///|
test "inserting at the front does not reorder common identities" {
  let (s, c) = basic_result(
    "[{\"id\":\"a\"},{\"id\":\"b\"}]",
    "[{\"id\":\"c\"},{\"id\":\"a\"},{\"id\":\"b\"}]",
    keyed_options("", "id", true),
  )
  assert_eq(summary_counts(s), (1, 0, 0, 0, 0))
  assert_eq(change_rows(c), [
    ("added", None, Some("/0"), false, None, true, Some("{\"id\":\"c\"}")),
  ])
  assert_eq(identity_rows(c), [Some((Some(""), Some(""), "id", "\"c\""))])
}

///|
test "deleting at the front does not reorder common identities" {
  let (s, c) = basic_result(
    "[{\"id\":\"c\"},{\"id\":\"a\"},{\"id\":\"b\"}]",
    "[{\"id\":\"a\"},{\"id\":\"b\"}]",
    keyed_options("", "id", true),
  )
  assert_eq(summary_counts(s), (0, 1, 0, 0, 0))
  assert_eq(change_rows(c), [
    ("removed", Some("/0"), None, true, Some("{\"id\":\"c\"}"), false, None),
  ])
  assert_eq(identity_rows(c), [Some((Some(""), Some(""), "id", "\"c\""))])
}

///|
test "matched field changes retain old zero and new two indices" {
  let (s, c) = basic_result(
    "{\"users\":[{\"id\":\"a\",\"quota\":1},{\"id\":\"b\"},{\"id\":\"c\"}]}",
    "{\"users\":[{\"id\":\"b\"},{\"id\":\"c\"},{\"id\":\"a\",\"quota\":2}]}",
    keyed_options("/users", "id", false),
  )
  assert_eq(summary_counts(s), (0, 0, 1, 0, 0))
  assert_eq(change_rows(c), [
    (
      "modified",
      Some("/users/0/quota"),
      Some("/users/2/quota"),
      true,
      Some("1"),
      true,
      Some("2"),
    ),
  ])
  assert_eq(identity_rows(c), [
    Some((Some("/users"), Some("/users"), "id", "\"a\"")),
  ])
}

///|
test "array reorder precedes sorted identity field changes" {
  let (s, c) = basic_result(
    "{\"users\":[{\"id\":\"a\",\"quota\":1},{\"id\":\"b\"},{\"id\":\"c\"}]}",
    "{\"users\":[{\"id\":\"b\"},{\"id\":\"c\"},{\"id\":\"a\",\"quota\":2}]}",
    keyed_options("/users", "id", true),
  )
  assert_eq(summary_counts(s), (0, 0, 1, 1, 0))
  assert_eq(change_rows(c), [
    (
      "reordered",
      Some("/users"),
      Some("/users"),
      true,
      Some("[\"a\",\"b\",\"c\"]"),
      true,
      Some("[\"b\",\"c\",\"a\"]"),
    ),
    (
      "modified",
      Some("/users/0/quota"),
      Some("/users/2/quota"),
      true,
      Some("1"),
      true,
      Some("2"),
    ),
  ])
  assert_eq(identity_rows(c), [
    None,
    Some((Some("/users"), Some("/users"), "id", "\"a\"")),
  ])
}

///|
test "string and integer identities remain distinct" {
  let (s, c) = basic_result(
    "[{\"id\":1,\"x\":0},{\"id\":\"1\",\"x\":0}]",
    "[{\"id\":\"1\",\"x\":1},{\"id\":1.0,\"x\":0}]",
    keyed_options("", "id", false),
  )
  assert_eq(summary_counts(s), (0, 0, 1, 0, 0))
  assert_eq(change_rows(c), [
    ("modified", Some("/1/x"), Some("/0/x"), true, Some("0"), true, Some("1")),
  ])
  assert_eq(identity_rows(c), [Some((Some(""), Some(""), "id", "\"1\""))])
}

///|
test "numeric identity notation equals but adjacent large integers differ" {
  let (s, c) = basic_result(
    "[{\"id\":1},{\"id\":9007199254740992}]",
    "[{\"id\":1e0},{\"id\":9007199254740993}]",
    keyed_options("", "id", true),
  )
  assert_eq(summary_counts(s), (1, 1, 0, 0, 0))
  assert_eq(change_rows(c), [
    (
      "removed",
      Some("/1"),
      None,
      true,
      Some("{\"id\":9007199254740992}"),
      false,
      None,
    ),
    (
      "added",
      None,
      Some("/1"),
      false,
      None,
      true,
      Some("{\"id\":9007199254740993}"),
    ),
  ])
  assert_eq(identity_rows(c), [
    Some((Some(""), Some(""), "id", "9007199254740992")),
    Some((Some(""), Some(""), "id", "9007199254740993")),
  ])
}

///|
test "changing identity removes and adds complete elements" {
  let (s, c) = basic_result(
    "[{\"id\":\"a\",\"x\":[1,2]}]",
    "[{\"id\":\"b\",\"x\":[1,2]}]",
    keyed_options("", "id", true),
  )
  assert_eq(summary_counts(s), (1, 1, 0, 0, 0))
  assert_eq(change_rows(c), [
    (
      "removed",
      Some("/0"),
      None,
      true,
      Some("{\"id\":\"a\",\"x\":[1,2]}"),
      false,
      None,
    ),
    (
      "added",
      None,
      Some("/0"),
      false,
      None,
      true,
      Some("{\"id\":\"b\",\"x\":[1,2]}"),
    ),
  ])
  assert_eq(identity_rows(c), [
    Some((Some(""), Some(""), "id", "\"a\"")),
    Some((Some(""), Some(""), "id", "\"b\"")),
  ])
}

///|
test "whole keyed array addition remains one change" {
  let (s, c) = basic_result(
    "{}",
    "{\"users\":[{\"v\":1,\"id\":\"a\"},{\"id\":\"b\"}]}",
    keyed_options("/users", "id", true),
  )
  assert_eq(summary_counts(s), (1, 0, 0, 0, 0))
  assert_eq(change_rows(c), [
    (
      "added",
      None,
      Some("/users"),
      false,
      None,
      true,
      Some("[{\"id\":\"a\",\"v\":1},{\"id\":\"b\"}]"),
    ),
  ])
  assert_eq(identity_rows(c), [None])
}

///|
test "whole keyed array removal remains one change" {
  let (s, c) = basic_result(
    "{\"users\":[{\"v\":1,\"id\":\"a\"},{\"id\":\"b\"}]}",
    "{}",
    keyed_options("/users", "id", true),
  )
  assert_eq(summary_counts(s), (0, 1, 0, 0, 0))
  assert_eq(change_rows(c), [
    (
      "removed",
      Some("/users"),
      None,
      true,
      Some("[{\"id\":\"a\",\"v\":1},{\"id\":\"b\"}]"),
      false,
      None,
    ),
  ])
  assert_eq(identity_rows(c), [None])
}

///|
test "rules use decoded escaped paths and empty identity key" {
  let (s, c) = basic_result(
    "{\"~/\":[{\"\":\"a\",\"v\":1}]}",
    "{\"~/\":[{\"\":\"a\",\"v\":2}]}",
    keyed_options("/~0~1", "", false),
  )
  assert_eq(summary_counts(s), (0, 0, 1, 0, 0))
  assert_eq(change_rows(c), [
    (
      "modified",
      Some("/~0~1/0/v"),
      Some("/~0~1/0/v"),
      true,
      Some("1"),
      true,
      Some("2"),
    ),
  ])
  assert_eq(identity_rows(c), [
    Some((Some("/~0~1"), Some("/~0~1"), "", "\"a\"")),
  ])
}

///|
test "new ancestor object is one change after descendant array validation" {
  let (s, c) = basic_result(
    "{}",
    "{\"group\":{\"users\":[{\"id\":\"a\"}]}}",
    keyed_options("/group/users", "id", false),
  )
  assert_eq(summary_counts(s), (1, 0, 0, 0, 0))
  assert_eq(change_rows(c), [
    (
      "added",
      None,
      Some("/group"),
      false,
      None,
      true,
      Some("{\"users\":[{\"id\":\"a\"}]}"),
    ),
  ])
  assert_eq(identity_rows(c), [None])
}

///|
test "identity context persists into nested positional arrays" {
  let (s, c) = basic_result(
    "[{\"id\":1.0,\"data\":[{\"v\":1}]}]",
    "[{\"id\":1,\"data\":[{\"v\":2}]}]",
    keyed_options("", "id", false),
  )
  assert_eq(summary_counts(s), (0, 0, 1, 0, 0))
  assert_eq(change_rows(c), [
    (
      "modified",
      Some("/0/data/0/v"),
      Some("/0/data/0/v"),
      true,
      Some("1"),
      true,
      Some("2"),
    ),
  ])
  assert_eq(identity_rows(c), [Some((Some(""), Some(""), "id", "1.0"))])
}

///|
test "typed identity sort is deterministic rather than numeric magnitude" {
  let (s, c) = basic_result(
    "[]",
    "[{\"id\":\"🌙\"},{\"id\":\"\"},{\"id\":\"b\"},{\"id\":\"aa\"},{\"id\":-1},{\"id\":2},{\"id\":10}]",
    keyed_options("", "id", false),
  )
  assert_eq(summary_counts(s), (7, 0, 0, 0, 0))
  assert_eq(change_rows(c), [
    ("added", None, Some("/6"), false, None, true, Some("{\"id\":10}")),
    ("added", None, Some("/5"), false, None, true, Some("{\"id\":2}")),
    ("added", None, Some("/4"), false, None, true, Some("{\"id\":-1}")),
    ("added", None, Some("/3"), false, None, true, Some("{\"id\":\"aa\"}")),
    ("added", None, Some("/2"), false, None, true, Some("{\"id\":\"b\"}")),
    ("added", None, Some("/1"), false, None, true, Some("{\"id\":\"\"}")),
    ("added", None, Some("/0"), false, None, true, Some("{\"id\":\"🌙\"}")),
  ])
  assert_eq(identity_rows(c), [
    Some((Some(""), Some(""), "id", "10")),
    Some((Some(""), Some(""), "id", "2")),
    Some((Some(""), Some(""), "id", "-1")),
    Some((Some(""), Some(""), "id", "\"aa\"")),
    Some((Some(""), Some(""), "id", "\"b\"")),
    Some((Some(""), Some(""), "id", "\"\"")),
    Some((Some(""), Some(""), "id", "\"🌙\"")),
  ])
}
