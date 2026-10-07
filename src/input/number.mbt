///|
/// Read-only canonical exact decimal representation. No floating payload.
pub struct NumberKey {
  negative : Bool
  digits : String
  exponent : Int
} derive(Eq, Debug)

///|
pub extend NumberKey with Eq::{equal, not_equal}

///|
pub extend NumberKey with Debug::{to_repr}

///|
fn number_error(code : @base.ErrorCode) -> @base.DiffError {
  let message = match code {
    NumberLimit =>
      "Number token exceeds 256 characters or explicit exponent exceeds 10000"
    _ => "Invalid JSON number token"
  }
  @base.Failure({
    code,
    message,
    side: None,
    path: None,
    line: None,
    column: None,
  })
}

///|
fn digit_at(token : String, index : Int) -> Bool {
  index < token.length() &&
  token.at(index).to_int() >= 48 &&
  token.at(index).to_int() <= 57
}

///|
pub fn normalize_number(token : String) -> NumberKey raise @base.DiffError {
  if token.length() > 256 {
    raise number_error(NumberLimit)
  }
  let length = token.length()
  let negative = token.has_prefix("-")
  let mut i = if negative { 1 } else { 0 }
  let integer_start = i
  if !digit_at(token, i) {
    raise number_error(ParseError)
  }
  if token.at(i).to_int() == 48 {
    i += 1
  } else {
    while digit_at(token, i) {
      i += 1
    }
  }
  let integer_end = i
  let mut fraction_start = i
  let mut fraction_end = i
  if i < length && token.at(i).to_int() == 46 {
    i += 1
    fraction_start = i
    if !digit_at(token, i) {
      raise number_error(ParseError)
    }
    while digit_at(token, i) {
      i += 1
    }
    fraction_end = i
  }
  let mut explicit_exponent = 0
  if i < length && (token.at(i).to_int() == 101 || token.at(i).to_int() == 69) {
    i += 1
    let exponent_negative = i < length && token.at(i).to_int() == 45
    if i < length && (token.at(i).to_int() == 43 || exponent_negative) {
      i += 1
    }
    if !digit_at(token, i) {
      raise number_error(ParseError)
    }
    while digit_at(token, i) {
      // The previous value is bounded by 10000, so this cannot overflow Int.
      explicit_exponent = explicit_exponent * 10 + token.at(i).to_int() - 48
      if explicit_exponent > 10000 {
        raise number_error(NumberLimit)
      }
      i += 1
    }
    if exponent_negative {
      explicit_exponent = -explicit_exponent
    }
  }
  if i != length {
    raise number_error(ParseError)
  }
  let coefficient = token[integer_start:integer_end].to_owned() +
    token[fraction_start:fraction_end].to_owned()
  let mut first = 0
  while first < coefficient.length() && coefficient.at(first).to_int() == 48 {
    first += 1
  }
  if first == coefficient.length() {
    return { negative: false, digits: "0", exponent: 0, }
  }
  let mut end = coefficient.length()
  while coefficient.at(end - 1).to_int() == 48 {
    end -= 1
  }
  {
    negative,
    digits: coefficient[first:end].to_owned(),
    exponent: explicit_exponent -
    (fraction_end - fraction_start) +
    coefficient.length() -
    end,
  }
}

///|
pub fn NumberKey::is_integer(self : NumberKey) -> Bool {
  self.exponent >= 0
}
