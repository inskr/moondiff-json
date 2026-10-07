// Generated from fixtures/reports/cases.json; input documents stay strings.

///|
test "config review demo" {
  let result = @bridge.analyze(
    "{\"timeout\":30,\"generated_at\":\"old\",\"stable\":true}", "{\"stable\":true,\"generated_at\":\"new\",\"timeout\":60}",
    "{\"ignore_paths\":[\"/generated_at\"]}",
  )
  assert_eq(
    result, "{\"schema_version\":\"1.0\",\"ok\":true,\"equal\":false,\"summary\":{\"added\":0,\"removed\":0,\"modified\":1,\"reordered\":0,\"ignored_subtrees\":1},\"changes\":[{\"kind\":\"modified\",\"old_path\":\"/timeout\",\"new_path\":\"/timeout\",\"before\":{\"present\":true,\"json_text\":\"30\"},\"after\":{\"present\":true,\"json_text\":\"60\"},\"identity\":null}]}",
  )
  for _ in 0..<3 {
    assert_eq(
      @bridge.analyze(
        "{\"timeout\":30,\"generated_at\":\"old\",\"stable\":true}", "{\"stable\":true,\"generated_at\":\"new\",\"timeout\":60}",
        "{\"ignore_paths\":[\"/generated_at\"]}",
      ),
      result,
    )
  }
  assert_true(@bridge.format_text(result).length() > 0)
}

///|
test "API keyed users demo" {
  let result = @bridge.analyze(
    "{\"users\":[{\"id\":\"a\",\"quota\":10},{\"id\":\"b\",\"quota\":20},{\"id\":\"c\",\"quota\":30}]}",
    "{\"users\":[{\"id\":\"c\",\"quota\":30},{\"id\":\"a\",\"quota\":10},{\"id\":\"b\",\"quota\":21}]}",
    "{\"array_rules\":[{\"path\":\"/users\",\"key\":\"id\"}]}",
  )
  assert_eq(
    result, "{\"schema_version\":\"1.0\",\"ok\":true,\"equal\":false,\"summary\":{\"added\":0,\"removed\":0,\"modified\":1,\"reordered\":0,\"ignored_subtrees\":0},\"changes\":[{\"kind\":\"modified\",\"old_path\":\"/users/1/quota\",\"new_path\":\"/users/2/quota\",\"before\":{\"present\":true,\"json_text\":\"20\"},\"after\":{\"present\":true,\"json_text\":\"21\"},\"identity\":{\"array_old_path\":\"/users\",\"array_new_path\":\"/users\",\"key\":\"id\",\"value_json\":\"\\\"b\\\"\"}}]}",
  )
  for _ in 0..<3 {
    assert_eq(
      @bridge.analyze(
        "{\"users\":[{\"id\":\"a\",\"quota\":10},{\"id\":\"b\",\"quota\":20},{\"id\":\"c\",\"quota\":30}]}",
        "{\"users\":[{\"id\":\"c\",\"quota\":30},{\"id\":\"a\",\"quota\":10},{\"id\":\"b\",\"quota\":21}]}",
        "{\"array_rules\":[{\"path\":\"/users\",\"key\":\"id\"}]}",
      ),
      result,
    )
  }
  assert_true(@bridge.format_text(result).length() > 0)
}

///|
test "API checked order demo" {
  let result = @bridge.analyze(
    "{\"users\":[{\"id\":\"a\"},{\"id\":\"b\"},{\"id\":\"c\"}]}", "{\"users\":[{\"id\":\"c\"},{\"id\":\"a\"},{\"id\":\"b\"}]}",
    "{\"array_rules\":[{\"path\":\"/users\",\"key\":\"id\",\"check_order\":true}]}",
  )
  assert_eq(
    result, "{\"schema_version\":\"1.0\",\"ok\":true,\"equal\":false,\"summary\":{\"added\":0,\"removed\":0,\"modified\":0,\"reordered\":1,\"ignored_subtrees\":0},\"changes\":[{\"kind\":\"reordered\",\"old_path\":\"/users\",\"new_path\":\"/users\",\"before\":{\"present\":true,\"json_text\":\"[\\\"a\\\",\\\"b\\\",\\\"c\\\"]\"},\"after\":{\"present\":true,\"json_text\":\"[\\\"c\\\",\\\"a\\\",\\\"b\\\"]\"},\"identity\":null}]}",
  )
  for _ in 0..<3 {
    assert_eq(
      @bridge.analyze(
        "{\"users\":[{\"id\":\"a\"},{\"id\":\"b\"},{\"id\":\"c\"}]}", "{\"users\":[{\"id\":\"c\"},{\"id\":\"a\"},{\"id\":\"b\"}]}",
        "{\"array_rules\":[{\"path\":\"/users\",\"key\":\"id\",\"check_order\":true}]}",
      ),
      result,
    )
  }
  assert_true(@bridge.format_text(result).length() > 0)
}

///|
test "large integer root demo" {
  let result = @bridge.analyze("9007199254740992", "9007199254740993", "{}")
  assert_eq(
    result, "{\"schema_version\":\"1.0\",\"ok\":true,\"equal\":false,\"summary\":{\"added\":0,\"removed\":0,\"modified\":1,\"reordered\":0,\"ignored_subtrees\":0},\"changes\":[{\"kind\":\"modified\",\"old_path\":\"\",\"new_path\":\"\",\"before\":{\"present\":true,\"json_text\":\"9007199254740992\"},\"after\":{\"present\":true,\"json_text\":\"9007199254740993\"},\"identity\":null}]}",
  )
  for _ in 0..<3 {
    assert_eq(
      @bridge.analyze("9007199254740992", "9007199254740993", "{}"),
      result,
    )
  }
  assert_true(@bridge.format_text(result).length() > 0)
}

///|
test "null missing slots" {
  let result = @bridge.analyze("{\"a\":null}", "{\"b\":null}", "{}")
  assert_eq(
    result, "{\"schema_version\":\"1.0\",\"ok\":true,\"equal\":false,\"summary\":{\"added\":1,\"removed\":1,\"modified\":0,\"reordered\":0,\"ignored_subtrees\":0},\"changes\":[{\"kind\":\"removed\",\"old_path\":\"/a\",\"new_path\":null,\"before\":{\"present\":true,\"json_text\":\"null\"},\"after\":{\"present\":false,\"json_text\":null},\"identity\":null},{\"kind\":\"added\",\"old_path\":null,\"new_path\":\"/b\",\"before\":{\"present\":false,\"json_text\":null},\"after\":{\"present\":true,\"json_text\":\"null\"},\"identity\":null}]}",
  )
  for _ in 0..<3 {
    assert_eq(@bridge.analyze("{\"a\":null}", "{\"b\":null}", "{}"), result)
  }
  assert_true(@bridge.format_text(result).length() > 0)
}

///|
test "exact notation equal" {
  let result = @bridge.analyze(
    "{\"b\":0,\"a\":1.0}", "{\"a\":1e0,\"b\":-0}", "{}",
  )
  assert_eq(
    result, "{\"schema_version\":\"1.0\",\"ok\":true,\"equal\":true,\"summary\":{\"added\":0,\"removed\":0,\"modified\":0,\"reordered\":0,\"ignored_subtrees\":0},\"changes\":[]}",
  )
  for _ in 0..<3 {
    assert_eq(
      @bridge.analyze("{\"b\":0,\"a\":1.0}", "{\"a\":1e0,\"b\":-0}", "{}"),
      result,
    )
  }
  assert_true(@bridge.format_text(result).length() > 0)
}

///|
test "duplicate identity visible error" {
  let result = @bridge.analyze(
    "{\"users\":[]}", "{\"users\":[{\"id\":1},{\"id\":1.0}]}", "{\"array_rules\":[{\"path\":\"/users\",\"key\":\"id\"}]}",
  )
  assert_eq(
    result, "{\"schema_version\":\"1.0\",\"ok\":false,\"error\":{\"code\":\"INVALID_ARRAY_KEY\",\"message\":\"Duplicate identity at array \\\"/users\\\", index 1\",\"side\":\"new\",\"path\":\"/users/1/id\",\"line\":null,\"column\":null}}",
  )
  for _ in 0..<3 {
    assert_eq(
      @bridge.analyze(
        "{\"users\":[]}", "{\"users\":[{\"id\":1},{\"id\":1.0}]}", "{\"array_rules\":[{\"path\":\"/users\",\"key\":\"id\"}]}",
      ),
      result,
    )
  }
  assert_true(@bridge.format_text(result).length() > 0)
}
