///|
fn option_failure(text : String, code : @base.ErrorCode) -> Unit raise {
  try @model.parse_options(text) |> ignore catch {
    @base.Failure(info) => {
      assert_eq(info.code, code)
      assert_eq(info.side, Some(@base.Options))
    }
  } noraise {
    _ => fail("invalid options accepted")
  }
}

///|
test "options decode pointers rules and exact integer limits" {
  let o = @model.parse_options(
    "{\"ignore_paths\":[\"/meta\",\"//~0~1\"],\"array_rules\":[{\"path\":\"/users\",\"key\":\"id\"}],\"limits\":{\"max_input_bytes\":1e3,\"max_depth\":0,\"max_nodes\":2.0,\"max_changes\":1}}",
  )
  assert_eq(o.ignore_paths, [["meta"], ["", "~/"]])
  assert_eq(o.array_rules[0].path, ["users"])
  assert_eq(o.array_rules[0].key, "id")
  assert_eq(o.array_rules[0].check_order, false)
  assert_eq(
    (
      o.limits.max_input_bytes,
      o.limits.max_depth,
      o.limits.max_nodes,
      o.limits.max_changes,
    ),
    (1000, 0, 2, 1),
  )
  let root = @model.parse_options(
    "{\"array_rules\":[{\"path\":\"\",\"key\":\"\",\"check_order\":true}]}",
  )
  assert_eq(root.array_rules[0].path, [])
  assert_eq(root.array_rules[0].key, "")
  assert_true(root.array_rules[0].check_order)
}

///|
test "options reject unknown fields missing rule properties and wrong types" {
  for
    text in [
      "[]", "null", "1", "{\"extra\":0}", "{\"ignore_paths\":null}", "{\"ignore_paths\":[1]}",
      "{\"array_rules\":{}}", "{\"array_rules\":[1]}", "{\"array_rules\":[{\"path\":\"/a\"}]}",
      "{\"array_rules\":[{\"key\":\"id\"}]}", "{\"array_rules\":[{\"path\":1,\"key\":\"id\"}]}",
      "{\"array_rules\":[{\"path\":\"/a\",\"key\":1}]}", "{\"array_rules\":[{\"path\":\"/a\",\"key\":\"id\",\"check_order\":0}]}",
      "{\"array_rules\":[{\"path\":\"/a\",\"key\":\"id\",\"mode\":\"position\"}]}",
      "{\"limits\":[]}", "{\"limits\":{\"max_extra\":1}}",
    ] {
    option_failure(text, @base.InvalidOptions)
  }
}

///|
test "options reject root ignore malformed pointers and duplicate decoded rule paths" {
  for
    text in [
      "{\"ignore_paths\":[\"\"]}", "{\"ignore_paths\":[\"a\"]}", "{\"ignore_paths\":[\"/~2\"]}",
      "{\"array_rules\":[{\"path\":\"#/a\",\"key\":\"id\"}]}", "{\"array_rules\":[{\"path\":\"/a\",\"key\":\"id\"},{\"path\":\"/\\u0061\",\"key\":\"name\"}]}",
    ] {
    option_failure(text, @base.InvalidOptions)
  }
  let o = @model.parse_options("{\"ignore_paths\":[\"/a\",\"/a\"]}")
  assert_eq(o.ignore_paths, [["a"]])
}

///|
test "option limits cannot be enlarged fractional negative or non numeric" {
  for field in ["max_input_bytes", "max_depth", "max_nodes", "max_changes"] {
    for value in ["-1", "0.5", "true", "\"1\"", "1e10000", "2147483648"] {
      option_failure(
        "{\"limits\":{\"" + field + "\":" + value + "}}",
        @base.InvalidOptions,
      )
    }
    if field != "max_depth" {
      option_failure("{\"limits\":{\"" + field + "\":0}}", @base.InvalidOptions)
    }
  }
  for
    (field, value) in [
      ("max_input_bytes", "2097153"),
      ("max_depth", "65"),
      ("max_nodes", "100001"),
      ("max_changes", "10001"),
    ] {
    option_failure(
      "{\"limits\":{\"" + field + "\":" + value + "}}",
      @base.InvalidOptions,
    )
  }
  let defaults = @model.parse_options("{}")
  assert_eq(defaults.limits.max_changes, 10000)
}

///|
test "options input is strict JSON with fixed parse and numeric protection" {
  option_failure("{\"limits\":{},\"limits\":{}}", @base.DuplicateKey)
  option_failure("{\"limits\":{\"max_depth\":1e10001}}", @base.NumberLimit)
  option_failure("{} trailing", @base.ParseError)
  option_failure("{\"ignore_paths\":[", @base.ParseError)
}
