///|
pub fn codepoint_compare(left : String, right : String) -> Int {
  let l = left.iter()
  let r = right.iter()
  while true {
    match (l.next(), r.next()) {
      (None, None) => return 0
      (None, Some(_)) => return -1
      (Some(_), None) => return 1
      (Some(a), Some(b)) => {
        if a.to_int() < b.to_int() {
          return -1
        }
        if a.to_int() > b.to_int() {
          return 1
        }
      }
    }
  } nobreak {
    0
  }
}
