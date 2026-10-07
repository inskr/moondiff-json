///|
fn raw_number(value : Json) -> String {
  match value {
    Number(_, repr=Some(token)) => token
    _ => "MISSING_NUMBER_TOKEN"
  }
}

///|
test "adjacent large integers preserve distinct original tokens" {
  let first = raw_number(@input.parse_input("9007199254740992"))
  let second = raw_number(@input.parse_input("9007199254740993"))
  assert_eq(first, "9007199254740992")
  assert_eq(second, "9007199254740993")
  assert_true(first != second)
}

///|
test "unrepresentable double exponent keeps its token" {
  assert_eq(raw_number(@input.parse_input("1e400")), "1e400")
}

///|
test "duplicate decoded object keys are rejected" {
  for text in ["{\"a\":1,\"a\":2}", "{\"a\":1,\"\\u0061\":2}"] {
    try @input.parse_input(text) |> ignore catch {
      @moonjson.Repeated(spot, key) => {
        assert_eq(key, "a")
        assert_true(spot.line >= 1 && spot.column >= 1)
      }
      _ => fail("wrong duplicate-key error")
    } noraise {
      _ => fail("duplicate key accepted")
    }
  }
}

///|
test "depth limit uses root zero and applies before parsing completes" {
  assert_true(@input.parse_input("0", max_depth=0) is Number(_, ..))
  assert_true(@input.parse_input("[]", max_depth=0) is Array([]))
  assert_true(@input.parse_input("[[0]]", max_depth=2) is Array(_))
  for text in ["[[0]]", "[[[[[[[[[[[[[[[[[[[["] {
    try @input.parse_input(text, max_depth=1) |> ignore catch {
      @moonjson.TooDeep(_) => ()
      _ => fail("expected parse-time depth error before truncated input")
    } noraise {
      _ => fail("depth overflow accepted")
    }
  }
}

///|
test "literal and escaped emoji decode to the same string" {
  assert_true(@input.parse_input("\"🌙\"") is String("🌙"))
  assert_true(@input.parse_input("\"\\ud83c\\udf19\"") is String("🌙"))
}

///|
test "strict JSON rejects extensions and trailing documents" {
  for text in ["[1,]", "/* comment */ 1", "01", "NaN", "1 2"] {
    try @input.parse_input(text) |> ignore catch {
      _ => ()
    } noraise {
      _ => fail("non-strict input accepted: \{text}")
    }
  }
}

///|
test "only one leading BOM is stripped" {
  assert_eq(raw_number(@input.parse_input("\u{FEFF}1")), "1")
  try @input.parse_input("\u{FEFF}\u{FEFF}1") |> ignore catch {
    _ => ()
  } noraise {
    _ => fail("two BOMs accepted")
  }
}
