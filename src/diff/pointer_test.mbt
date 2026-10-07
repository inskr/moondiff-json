///|
test "pointer roots and empty member names are distinct" {
  assert_eq(@diff.pointer_encode([]), "")
  assert_eq(@diff.pointer_encode([""]), "/")
  assert_eq(@diff.pointer_encode(["", ""]), "//")
  assert_eq(@diff.pointer_decode(""), [])
  assert_eq(@diff.pointer_decode("/"), [""])
  assert_eq(@diff.pointer_decode("//"), ["", ""])
}

///|
test "RFC 6901 escaping is reversible without URI percent decoding" {
  assert_eq(
    @diff.pointer_encode(["~/", "a/b", "~1", "中文🌙", "%20"]),
    "/~0~1/a~1b/~01/中文🌙/%20",
  )
  assert_eq(@diff.pointer_decode("/~0~1/a~1b/~01/中文🌙/%20"), [
    "~/", "a/b", "~1", "中文🌙", "%20",
  ])
  assert_eq(@diff.pointer_decode("/a/"), ["a", ""])
  assert_eq(@diff.pointer_decode("/~10"), ["/0"])
}

///|
test "invalid pointer escapes and URI fragments return INVALID_OPTIONS" {
  for pointer in ["x", "#/a", "/~", "/~2", "/a~9b", "/~~0"] {
    try @diff.pointer_decode(pointer) |> ignore catch {
      @base.Failure(info) => {
        assert_eq(info.code, @base.InvalidOptions)
        assert_eq(info.side, Some(@base.Options))
        // The invalid pointer is input text, not a known RFC 6901 error location.
        assert_eq(info.path, None)
      }
    } noraise {
      _ => fail("invalid pointer accepted")
    }
  }
}
