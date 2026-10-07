///|
test "absent and genuine null slots cannot be confused" {
  let absent = @model.ValueSlot::absent()
  let null_value = @model.ValueSlot::present_json("null")
  assert_eq((absent.present, absent.json_text), (false, None))
  assert_eq((null_value.present, null_value.json_text), (true, Some("null")))
  let large = @model.ValueSlot::present_json("9007199254740993")
  assert_eq(large.json_text, Some("9007199254740993"))
}

///|
test "Document numeric nodes contain exact keys and preserved source tokens" {
  let document = @model.parse_document(
    "[1.0,1e0,9007199254740993]",
    @model.Side::Old,
    @model.default_limits(),
  )
  assert_eq(document.node_count, 4)
  match document.root() {
    @model.Value::Array(values) => {
      assert_true(values[0] is @model.Value::Number("1.0", _))
      match (values[0], values[1], values[2]) {
        (
          @model.Value::Number(_, a),
          @model.Value::Number(_, b),
          @model.Value::Number(raw, large),
        ) => {
          assert_eq(a, b)
          assert_eq(raw, "9007199254740993")
          assert_eq(large.digits, "9007199254740993")
        }
        _ => fail("numeric values were not converted")
      }
    }
    _ => fail("root array lost")
  }
}

///|
test "Document preserves null booleans empty containers and decoded strings" {
  let document = @model.parse_document(
    "[null,true,false,{},[],\"\\u4e2d🌙\"]",
    @model.Side::Old,
    @model.default_limits(),
  )
  match document.root() {
    @model.Value::Array(values) => {
      assert_true(values[0] is @model.Value::Null)
      assert_true(values[1] is @model.Value::Boolean(true))
      assert_true(values[2] is @model.Value::Boolean(false))
      assert_true(values[3] is @model.Value::Object(_))
      assert_true(values[4] is @model.Value::Array([]))
      assert_true(values[5] is @model.Value::String("中🌙"))
    }
    _ => fail("root container lost")
  }
}

///|
test "Document rejects invalid input and preserves error side" {
  for
    (text, side, code) in [
      ("{\"a\":1,\"a\":2}", @model.Side::Old, @model.ErrorCode::DuplicateKey),
      ("1e10001", @model.Side::New, @model.ErrorCode::NumberLimit),
      ("1 2", @model.Side::Options, @model.ErrorCode::ParseError),
    ] {
    try
      @model.parse_document(text, side, @model.default_limits()) |> ignore
    catch {
      @model.DiffError::Failure(info) => {
        assert_eq(info.code, code)
        assert_eq(info.side, Some(side))
      }
    } noraise {
      _ => fail("invalid Document constructed")
    }
  }
}

///|
test "Document snapshots cannot mutate the validated stored tree" {
  let document = @model.parse_document(
    "{\"items\":[1]}",
    @model.Side::Old,
    @model.default_limits(),
  )
  match document.root() {
    @model.Value::Object(members) => {
      match members.get("items") {
        Some(@model.Value::Array(items)) => items.clear()
        _ => fail("items missing")
      }
      members.clear()
    }
    _ => fail("object missing")
  }
  match document.root() {
    @model.Value::Object(members) => {
      assert_eq(members.length(), 1)
      match members.get("items") {
        Some(@model.Value::Array(items)) => assert_eq(items.length(), 1)
        _ => fail("snapshot mutated stored array")
      }
    }
    _ => fail("snapshot mutated stored object")
  }
}

///|
test "Document respects lower UTF-8 byte node and root-zero depth limits" {
  let bytes = @model.Limits::new(max_input_bytes=6)
  assert_true(
    @model.parse_document("\"🌙\"", @model.Side::New, bytes).root()
    is @model.Value::String("🌙"),
  )
  try
    @model.parse_document("\"🌙\" ", @model.Side::New, bytes) |> ignore
  catch {
    @model.DiffError::Failure(info) =>
      assert_eq(info.code, @model.ErrorCode::InputLimit)
  } noraise {
    _ => fail("UTF-8 byte limit bypassed")
  }
  let nodes = @model.Limits::new(max_nodes=2)
  assert_eq(@model.parse_document("[0]", @model.Side::Old, nodes).node_count, 2)
  try @model.parse_document("[0,1]", @model.Side::Old, nodes) |> ignore catch {
    @model.DiffError::Failure(info) =>
      assert_eq(info.code, @model.ErrorCode::NodeLimit)
  } noraise {
    _ => fail("node limit bypassed")
  }
  let depth = @model.Limits::new(max_depth=0)
  assert_eq(@model.parse_document("{}", @model.Side::Old, depth).node_count, 1)
  try @model.parse_document("[0]", @model.Side::Old, depth) |> ignore catch {
    @model.DiffError::Failure(info) =>
      assert_eq(info.code, @model.ErrorCode::DepthLimit)
  } noraise {
    _ => fail("depth limit bypassed")
  }
}

///|
test "limits cannot be enlarged or made non-positive" {
  for
    construct in [
      () => @model.Limits::new(max_depth=65),
      () => @model.Limits::new(max_nodes=100001),
      () => @model.Limits::new(max_input_bytes=2097153),
      () => @model.Limits::new(max_changes=10001),
      () => @model.Limits::new(max_nodes=0),
      () => @model.Limits::new(max_depth=-1),
    ] {
    try construct() |> ignore catch {
      @model.DiffError::Failure(info) =>
        assert_eq(info.code, @model.ErrorCode::InvalidOptions)
    } noraise {
      _ => fail("invalid Limits constructed")
    }
  }
}
