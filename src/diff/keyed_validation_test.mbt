///|
test "each side rejects missing duplicate and non object identities" {
  for
    (bad, index) in [
      ("[{\"id\":\"a\"},{}]", 1),
      ("[{\"id\":\"a\"},{\"id\":\"a\"}]", 1),
      ("[{\"id\":1},{\"id\":1.0}]", 1),
      ("[{\"id\":0},{\"id\":-0.0}]", 1),
      ("[{\"id\":\"a\"},{\"id\":\"\\u0061\"}]", 1),
      ("[null]", 0),
      ("[1]", 0),
      ("[[]]", 0),
    ] {
    assert_identity_error(bad, "[]", "", @base.Old, index)
    assert_identity_error("[]", bad, "", @base.New, index)
  }
}

///|
test "only strings or exact mathematical integers are valid identities" {
  for value in ["null", "true", "false", "0.1", "1e-1", "[]", "{}"] {
    let bad = "{\"users\":[{\"id\":" + value + "}]}"
    assert_identity_error(bad, "{\"users\":[]}", "/users", @base.Old, 0)
    assert_identity_error("{\"users\":[]}", bad, "/users", @base.New, 0)
  }
  let (s, _) = basic_result(
    "[{\"id\":1.2e1},{\"id\":1e10000},{\"id\":\"\"}]",
    "[{\"id\":\"\"},{\"id\":1e10000},{\"id\":12.0}]",
    keyed_options("", "id", false),
  )
  assert_eq(summary_counts(s), (0, 0, 0, 0, 0))
}

///|
test "rules require an existing array on at least one side and reject non arrays" {
  let options = keyed_options("/users", "id", false)
  for
    (old, new) in [
      ("{}", "{}"),
      ("{\"users\":null}", "{\"users\":[]}"),
      ("{\"users\":[]}", "{\"users\":{}}"),
      ("{\"users\":1}", "{}"),
      ("{}", "{\"users\":true}"),
    ] {
    assert_option_error(old, new, options)
  }
  for (old, new) in [("{\"users\":[[]]}", "{}"), ("{}", "{\"users\":[[]]}")] {
    assert_option_error(old, new, keyed_options("/users/0", "id", false))
  }
}

///|
test "whole added removed arrays and added ancestors validate identities first" {
  assert_identity_error("{}", "{\"users\":[{}]}", "/users", @base.New, 0)
  assert_identity_error("{\"users\":[{}]}", "{}", "/users", @base.Old, 0)
  assert_identity_error(
    "{}",
    "{\"group\":{\"users\":[{}]}}",
    "/group/users",
    @base.New,
    0,
  )
}

///|
test "overlapping ignore skips keyed data validation but preserves config checks" {
  let options = {
    ..keyed_options("/users", "id", true),
    ignore_paths: [["users"]],
  }
  let (s, c) = basic_result(
    "{\"users\":[{},{}]}", "{\"users\":[false]}", options,
  )
  assert_eq(summary_counts(s), (0, 0, 0, 0, 1))
  assert_eq(c.length(), 0)
  let (missing, _) = basic_result("{}", "{}", options)
  assert_eq(summary_counts(missing), (0, 0, 0, 0, 0))
  let duplicate = {
    ..options,
    array_rules: [options.array_rules[0], options.array_rules[0]],
  }
  assert_option_error("{}", "{}", duplicate)
  let parent = {
    ..keyed_options("/group/users", "id", false),
    ignore_paths: [["group"]],
  }
  let (s, _) = basic_result("{}", "{\"group\":{\"users\":[{}]}}", parent)
  assert_eq(summary_counts(s), (0, 0, 0, 0, 1))
}

///|
test "multiple keyed rules use deterministic object order" {
  let a = keyed_options("/b", "id", false)
  let options = {
    ..a,
    array_rules: [
      a.array_rules[0],
      { path: ["a"], key: "id", check_order: false, },
    ],
  }
  let (s, c) = basic_result(
    "{\"a\":[{\"id\":1,\"v\":0}],\"b\":[{\"id\":2,\"v\":0}]}", "{\"b\":[{\"id\":2,\"v\":1}],\"a\":[{\"id\":1,\"v\":1}]}",
    options,
  )
  assert_eq(summary_counts(s), (0, 0, 2, 0, 0))
  assert_eq(c.map(c => c.new_path), [Some("/a/0/v"), Some("/b/0/v")])
}

///|
test "keyed change limit counts reorder before element changes" {
  let options = {
    ..keyed_options("", "id", true),
    limits: @model.Limits::new(max_changes=1),
  }
  let old = "[{\"id\":\"a\",\"v\":0},{\"id\":\"b\"}]"
  let new = "[{\"id\":\"b\"},{\"id\":\"a\",\"v\":1}]"
  try basic_result(old, new, options) |> ignore catch {
    @base.Failure(info) => assert_eq(info.code, @base.ChangeLimit)
    _ => fail("unexpected error")
  } noraise {
    _ => fail("partial success after keyed change limit")
  }
}

///|
test "unconfigured object arrays stay positional and keyed inputs stay immutable" {
  let old_text = "[{\"id\":\"a\"},{\"id\":\"b\"}]"
  let new_text = "[{\"id\":\"b\"},{\"id\":\"a\"}]"
  let options = keyed_options("", "id", false)
  let old = @model.parse_document(old_text, @base.Old, options.limits)
  let new = @model.parse_document(new_text, @base.New, options.limits)
  match @diff.diff_documents(old, new, options) {
    @model.Success(s, _) => assert_eq(summary_counts(s), (0, 0, 0, 0, 0))
    _ => fail("unexpected error")
  }
  match @diff.diff_documents(old, new, @model.Options::default()) {
    @model.Success(s, c) => {
      assert_eq(summary_counts(s), (0, 0, 2, 0, 0))
      assert_eq(c[0].old_path, Some("/0/id"))
    }
    _ => fail("unexpected error")
  }
  assert_eq(options.array_rules[0].path, [])
}
