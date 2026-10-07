///|
/// Bounded decimal-to-Int conversion, with no floating operation or overflow.
pub fn NumberKey::bounded_int(self : NumberKey, max : Int) -> Int? {
  if self.negative || !self.is_integer() {
    return None
  }
  let mut result = 0
  for c in self.digits.iter() {
    let digit = c.to_int() - 48
    if result > (max - digit) / 10 || digit > max {
      return None
    }
    result = result * 10 + digit
  }
  for _ in 0..<self.exponent {
    if result > max / 10 {
      return None
    }
    result *= 10
  }
  Some(result)
}
