///|
test "keyed swap self and repeat preserve paths slots and counts" {
  let old = "[{\"id\":\"a\",\"v\":0},{\"id\":\"b\"},{\"id\":\"c\"}]"
  let new = "[{\"id\":\"c\"},{\"id\":\"a\",\"v\":1},{\"id\":\"d\"}]"
  let options = keyed_options("", "id", true)
  let (s, c) = basic_result(old, new, options)
  assert_eq(summary_counts(s), (1, 1, 1, 1, 0))
  assert_eq(c[0].before.json_text, Some("[\"a\",\"c\"]"))
  assert_eq(c[0].after.json_text, Some("[\"c\",\"a\"]"))
  let (r, rc) = basic_result(new, old, options)
  assert_eq(
    (s.added, s.removed, s.modified, s.reordered),
    (r.removed, r.added, r.modified, r.reordered),
  )
  assert_eq(
    change_rows(c).map(row => {
      let (kind, op, np, bp, bt, ap, at) = row
      let kind = match kind {
        "added" => "removed"
        "removed" => "added"
        _ => kind
      }
      (kind, np, op, ap, at, bp, bt)
    }),
    change_rows(rc),
  )
  for _ in 0..<3 {
    let (repeat, cc) = basic_result(old, new, options)
    assert_eq(summary_counts(s), summary_counts(repeat))
    assert_eq(change_rows(c), change_rows(cc))
    assert_eq(identity_rows(c), identity_rows(cc))
  }
  for text in [old, new] {
    let (s, c) = basic_result(text, text, options)
    assert_eq(summary_counts(s), (0, 0, 0, 0, 0))
    assert_eq(c.length(), 0)
  }
}

///|
test "reverse ten thousand identities uses keyed matching and one reorder" {
  let old = StringBuilder()
  let new = StringBuilder()
  old.write_char('[')
  new.write_char('[')
  for i in 0..<10000 {
    if i > 0 {
      old.write_char(',')
      new.write_char(',')
    }
    old.write_string("{\"id\":" + i.to_string() + ",\"v\":0}")
    new.write_string("{\"id\":" + (9999 - i).to_string() + ",\"v\":0}")
  }
  old.write_char(']')
  new.write_char(']')
  let old = old.to_string()
  let new = new.to_string()
  let (s, c) = basic_result(old, new, keyed_options("", "id", false))
  assert_eq(summary_counts(s), (0, 0, 0, 0, 0))
  assert_eq(c.length(), 0)
  let (s, c) = basic_result(old, new, keyed_options("", "id", true))
  assert_eq(summary_counts(s), (0, 0, 0, 1, 0))
  assert_eq(c.length(), 1)
  assert_true(c[0].before.json_text.unwrap().has_prefix("[0,1,2,"))
  assert_true(c[0].after.json_text.unwrap().has_prefix("[9999,9998,9997,"))
}
