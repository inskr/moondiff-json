///|
test "canonical decimals preserve exact equality and distinct large integers" {
  let cases = [
    ("1", false, "1", 0),
    ("1.0", false, "1", 0),
    ("1e0", false, "1", 0),
    ("0", false, "0", 0),
    ("-0", false, "0", 0),
    ("-0.000e-9999", false, "0", 0),
    ("1.20e2", false, "12", 1),
    ("120", false, "12", 1),
    ("-0.001200", true, "12", -4),
    ("123.4500E-2", false, "12345", -4),
    ("9007199254740992", false, "9007199254740992", 0),
    ("9007199254740993", false, "9007199254740993", 0),
  ]
  for (token, negative, digits, exponent) in cases {
    let key = @input.normalize_number(token)
    assert_eq(
      (key.negative, key.digits, key.exponent),
      (negative, digits, exponent),
    )
  }
  assert_eq(@input.normalize_number("1"), @input.normalize_number("1.0"))
  assert_true(
    @input.normalize_number("9007199254740992") !=
    @input.normalize_number("9007199254740993"),
  )
}

///|
test "number token length 256 accepted and 257 rejected" {
  let key = @input.normalize_number("1".repeat(256))
  assert_eq(key.digits.length(), 256)
  try @input.normalize_number("1".repeat(257)) |> ignore catch {
    @base.Failure(info) => assert_eq(info.code, @base.NumberLimit)
  } noraise {
    _ => fail("257-character token accepted")
  }
}

///|
test "explicit exponent boundary is checked without expansion or overflow" {
  for
    (token, digits, exponent) in [
      ("1e10000", "1", 10000),
      ("1e-10000", "1", -10000),
      ("10e10000", "1", 10001),
      ("0.1e-10000", "1", -10001),
      ("1e+00010000", "1", 10000),
    ] {
    let key = @input.normalize_number(token)
    assert_eq((key.digits, key.exponent), (digits, exponent))
  }
  for token in ["1e10001", "1e-10001", "0e10001", "1e999999999999999999999999"] {
    try @input.normalize_number(token) |> ignore catch {
      @base.Failure(info) => assert_eq(info.code, @base.NumberLimit)
    } noraise {
      _ => fail("exponent overflow accepted")
    }
  }
}

///|
test "standalone normalization rejects malformed or non-ASCII tokens" {
  for
    token in [
      "", "+1", "01", "-", ".1", "1.", "1e", "1e+", "1 2", "NaN", "Infinity", "١",
      "1🌙",
    ] {
    try @input.normalize_number(token) |> ignore catch {
      @base.Failure(info) => assert_eq(info.code, @base.ParseError)
    } noraise {
      _ => fail("invalid number accepted: \{token}")
    }
  }
}

///|
test "identity integer classification uses canonical decimal exponent" {
  for token in ["0", "-0.0", "1", "1.0", "1e4", "12.00", "1.20e2"] {
    assert_true(@input.normalize_number(token).is_integer())
  }
  for token in ["1.2", "1e-1", "-0.001", "12e-3"] {
    assert_true(!@input.normalize_number(token).is_integer())
  }
}
