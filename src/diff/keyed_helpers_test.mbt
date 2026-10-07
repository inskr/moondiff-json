///|
fn keyed_options(
  path : String,
  key : String,
  check_order : Bool,
) -> @model.Options raise {
  {
    ..@model.Options::default(),
    array_rules: [{ path: @diff.pointer_decode(path), key, check_order, }],
  }
}

///|
fn identity_rows(
  changes : Array[@model.Change],
) -> Array[(String?, String?, String, String)?] {
  changes.map(c => {
    c.identity.map(i => {
      (i.array_old_path, i.array_new_path, i.key, i.value_json)
    })
  })
}

///|
fn assert_identity_error(
  old : String,
  new : String,
  path : String,
  side : @base.Side,
  index : Int,
) -> Unit raise {
  try basic_result(old, new, keyed_options(path, "id", false)) |> ignore catch {
    @base.Failure(info) => {
      assert_eq(info.code, @base.InvalidArrayKey)
      assert_eq(info.side, Some(side))
      assert_eq(info.path, Some(path + "/" + index.to_string() + "/id"))
      assert_true(info.message.contains("index " + index.to_string()))
      assert_true(info.message.contains("array " + @report.quote_string(path)))
    }
    _ => fail("unexpected error type")
  } noraise {
    _ => fail("invalid identity accepted")
  }
}
