///|
test "fixed corpus has swap symmetry self equality and deterministic repeat" {
  let pairs = [
    ("{\"z\":[1,2],\"a\":null}", "{\"z\":[2],\"b\":false}"),
    ("[1,{\"a\":2}]", "[0,{\"b\":3},[]]"),
    ("9007199254740992", "9007199254740993"),
    ("{\"~/\":true}", "{\"~/\":false}"),
    ("{}", "[null]"),
  ]
  for (old, new) in pairs {
    let (s, c) = basic_result(old, new, @model.Options::default())
    assert_true(c.length() > 0)
    let (r, rc) = basic_result(new, old, @model.Options::default())
    assert_eq(
      (s.added, s.removed, s.modified, s.reordered),
      (r.removed, r.added, r.modified, r.reordered),
    )
    let swapped = change_rows(c).map(row => {
      let (kind, op, np, bp, bt, ap, at) = row
      let kind = match kind {
        "added" => "removed"
        "removed" => "added"
        _ => kind
      }
      (kind, np, op, ap, at, bp, bt)
    })
    assert_eq(swapped, change_rows(rc))
    for _ in 0..<3 {
      let (repeat, cc) = basic_result(old, new, @model.Options::default())
      assert_eq(summary_counts(s), summary_counts(repeat))
      assert_eq(change_rows(c), change_rows(cc))
    }
    for text in [old, new] {
      let (equal, ec) = basic_result(text, text, @model.Options::default())
      assert_eq(summary_counts(equal), (0, 0, 0, 0, 0))
      assert_eq(ec.length(), 0)
    }
    for change in c {
      assert_true(change.identity is None)
    }
  }
}

///|
test "ignoring does not mutate validated documents or caller options" {
  let options = ignoring(["/a"])
  let old = @model.parse_document("{\"a\":1}", @base.Old, options.limits)
  let new = @model.parse_document("{\"a\":2}", @base.New, options.limits)
  match @diff.diff_documents(old, new, options) {
    @model.Success(s, _) => assert_eq(s.ignored_subtrees, 1)
    _ => fail("unexpected error")
  }
  match @diff.diff_documents(old, new, @model.Options::default()) {
    @model.Success(s, c) => {
      assert_eq(s.modified, 1)
      assert_eq(c[0].before.json_text, Some("1"))
      assert_eq(c[0].after.json_text, Some("2"))
    }
    _ => fail("unexpected error")
  }
  assert_eq(options.ignore_paths, [["a"]])
}

///|
test "ignored inputs are still fully validated before comparison" {
  let options = ignoring(["/meta"])
  for
    (text, code) in [
      ("{\"meta\":{\"x\":1,\"x\":2}}", @base.DuplicateKey),
      ("{\"meta\":1e10001}", @base.NumberLimit),
    ] {
    try basic_result(text, "{}", options) |> ignore catch {
      @base.Failure(info) => {
        assert_eq(info.code, code)
        assert_eq(info.side, Some(@base.Old))
      }
      _ => fail("unexpected error")
    } noraise {
      _ => fail("ignored invalid input accepted")
    }
  }
}
