///|
fn repeat_piece(piece : String, count : Int) -> String {
  let out = StringBuilder()
  for _ in 0..<count {
    out.write_string(piece)
  }
  out.to_string()
}

///|
fn assert_analyze_error(
  old : String,
  new : String,
  options : String,
  code : String,
  side : String?,
) -> Unit raise {
  let result = @bridge.analyze(old, new, options)
  match @input.parse_input(result) {
    Json::Object(top) => {
      assert_eq(top.length(), 3)
      assert_true(top.get("schema_version") is Some(Json::String("1.0")))
      assert_true(top.get("ok") is Some(Json::False))
      match top.get("error") {
        Some(Json::Object(info)) => {
          assert_eq(info.length(), 6)
          assert_true(info.get("code") is Some(Json::String(c)) && c == code)
          match (info.get("side"), side) {
            (Some(Json::Null), None) => ()
            (Some(Json::String(actual)), Some(expected)) =>
              assert_eq(actual, expected)
            _ => fail("wrong error side")
          }
        }
        _ => fail("error details missing")
      }
    }
    _ => fail("report is not an envelope")
  }
  assert_eq(result, @bridge.analyze(old, new, options))
}

///|
fn assert_equal_analyze(
  old : String,
  new : String,
  options : String,
) -> Unit raise {
  match @input.parse_input(@bridge.analyze(old, new, options)) {
    Json::Object(top) => {
      assert_true(top.get("ok") is Some(Json::True))
      assert_true(top.get("equal") is Some(Json::True))
    }
    _ => fail("success envelope missing")
  }
}

///|
test "options validation precedes documents and lower limits do not constrain options themselves" {
  assert_analyze_error(
    "invalid",
    "invalid",
    "{\"unknown\":1}",
    "INVALID_OPTIONS",
    Some("options"),
  )
  assert_analyze_error(
    "invalid",
    "invalid",
    "{\"limits\":{},\"limits\":{}}",
    "DUPLICATE_KEY",
    Some("options"),
  )
  assert_equal_analyze(
    "0", "0", "{\"limits\":{\"max_input_bytes\":1,\"max_depth\":0,\"max_nodes\":1}}",
  )
}

///|
test "UTF8 bytes nodes and root zero depth honor exact and exceeded limits on both sides" {
  assert_equal_analyze(
    "\"🌙\"", "\"🌙\"", "{\"limits\":{\"max_input_bytes\":6}}",
  )
  assert_analyze_error(
    "\"🌙\" ",
    "0",
    "{\"limits\":{\"max_input_bytes\":6}}",
    "INPUT_LIMIT",
    Some("old"),
  )
  assert_analyze_error(
    "0",
    "\"🌙\" ",
    "{\"limits\":{\"max_input_bytes\":6}}",
    "INPUT_LIMIT",
    Some("new"),
  )
  assert_equal_analyze("[0]", "[0]", "{\"limits\":{\"max_nodes\":2}}")
  assert_analyze_error(
    "0",
    "[0,1]",
    "{\"limits\":{\"max_nodes\":2}}",
    "NODE_LIMIT",
    Some("new"),
  )
  assert_equal_analyze("{}", "{}", "{\"limits\":{\"max_depth\":0}}")
  assert_analyze_error(
    "[0]",
    "{}",
    "{\"limits\":{\"max_depth\":0}}",
    "DEPTH_LIMIT",
    Some("old"),
  )
  assert_equal_analyze("[[0]]", "[[0]]", "{\"limits\":{\"max_depth\":2}}")
  assert_analyze_error(
    "0",
    "[[[0]]]",
    "{\"limits\":{\"max_depth\":2}}",
    "DEPTH_LIMIT",
    Some("new"),
  )
}

///|
test "ignored subtrees still reject duplicate keys and all input resource overflows" {
  assert_analyze_error(
    "{\"meta\":{\"x\":1,\"x\":2}}",
    "{}",
    "{\"ignore_paths\":[\"/meta\"]}",
    "DUPLICATE_KEY",
    Some("old"),
  )
  assert_analyze_error(
    "{}",
    "{\"meta\":1e10001}",
    "{\"ignore_paths\":[\"/meta\"]}",
    "NUMBER_LIMIT",
    Some("new"),
  )
  let o = "{\"ignore_paths\":[\"/meta\"],\"limits\":{\"max_nodes\":3,\"max_depth\":2,\"max_input_bytes\":16}}"
  assert_equal_analyze("{\"meta\":[0]}", "{\"meta\":[1]}", o)
  assert_analyze_error("{}", "{\"meta\":[0,1]}", o, "NODE_LIMIT", Some("new"))
  assert_analyze_error("{\"meta\":[[0]]}", "{}", o, "DEPTH_LIMIT", Some("old"))
  assert_analyze_error(
    "{}",
    "{\"meta\":\"123456789\"}",
    o,
    "INPUT_LIMIT",
    Some("new"),
  )
}

///|
test "default two MiB bytes are accepted and one extra byte is rejected" {
  let chunk = repeat_piece("x", 1024)
  let exact = "\"" + repeat_piece(chunk, 2047) + repeat_piece("x", 1022) + "\""
  assert_eq(exact.length(), 2097152)
  assert_equal_analyze(exact, exact, "{}")
  assert_analyze_error(exact + " ", "0", "{}", "INPUT_LIMIT", Some("old"))
  let padded = "{}" + repeat_piece(" ", 2097150)
  assert_equal_analyze("0", "0", padded)
  assert_analyze_error("0", "0", padded + " ", "INPUT_LIMIT", Some("options"))
}

///|
test "default option node depth and numeric limits cannot be raised or bypassed" {
  let paths = "{\"ignore_paths\":[" +
    repeat_piece("\"/absent\",", 99997) +
    "\"/absent\"]}"
  assert_equal_analyze("0", "0", paths)
  assert_analyze_error(
    "0",
    "0",
    "{\"ignore_paths\":[" +
    repeat_piece("\"/absent\",", 99998) +
    "\"/absent\"]}",
    "NODE_LIMIT",
    Some("options"),
  )
  let nested = repeat_piece("[", 63) + "0" + repeat_piece("]", 63)
  assert_analyze_error(
    "0",
    "0",
    "{\"extra\":" + nested + "}",
    "INVALID_OPTIONS",
    Some("options"),
  )
  assert_analyze_error(
    "0",
    "0",
    "{\"extra\":[" + nested + "]}",
    "DEPTH_LIMIT",
    Some("options"),
  )
  assert_analyze_error(
    "0",
    "0",
    "{\"limits\":{\"max_nodes\":" + repeat_piece("9", 256) + "}}",
    "INVALID_OPTIONS",
    Some("options"),
  )
  assert_analyze_error(
    "0",
    "0",
    "{\"limits\":{\"max_nodes\":" + repeat_piece("9", 257) + "}}",
    "NUMBER_LIMIT",
    Some("options"),
  )
}

///|
test "ten thousand changes produce complete reports and next change produces only error" {
  let old = "[" + repeat_piece("0,", 9999) + "0]"
  let new = "[" + repeat_piece("1,", 9999) + "1]"
  let result = @bridge.analyze(old, new, "{}")
  match @input.parse_input(result) {
    Json::Object(top) => {
      assert_true(top.get("ok") is Some(Json::True))
      match top.get("changes") {
        Some(Json::Array(c)) => assert_eq(c.length(), 10000)
        _ => fail("complete changes missing")
      }
    }
    _ => fail("success missing")
  }
  let text = @bridge.format_text(result)
  assert_true(
    text.has_prefix("equal: false\nadded: 0 removed: 0 modified: 10000"),
  )
  assert_true(text.contains("new=\"/9999\""))
  assert_analyze_error(
    "[" + repeat_piece("0,", 10000) + "0]",
    "[" + repeat_piece("1,", 10000) + "1]",
    "{}",
    "CHANGE_LIMIT",
    None,
  )
}

///|
test "documents honor default node depth and number token boundaries" {
  let nodes = "[" + repeat_piece("0,", 99998) + "0]"
  assert_equal_analyze(nodes, nodes, "{}")
  assert_analyze_error(
    "[" + repeat_piece("0,", 99999) + "0]",
    "0",
    "{}",
    "NODE_LIMIT",
    Some("old"),
  )
  let depth = repeat_piece("[", 64) + "0" + repeat_piece("]", 64)
  assert_equal_analyze(depth, depth, "{}")
  assert_analyze_error("0", "[" + depth + "]", "{}", "DEPTH_LIMIT", Some("new"))
  let token = repeat_piece("9", 256)
  assert_equal_analyze(token, token, "{}")
  assert_analyze_error(token + "9", "0", "{}", "NUMBER_LIMIT", Some("old"))
  assert_equal_analyze("1e10000", "10e9999", "{}")
  assert_analyze_error("0", "1e10001", "{}", "NUMBER_LIMIT", Some("new"))
}
