///|
pub fn pointer_encode(tokens : Array[String]) -> String {
  let out = StringBuilder()
  for token in tokens {
    out.write_char('/')
    for character in token.iter() {
      match character {
        '~' => out.write_string("~0")
        '/' => out.write_string("~1")
        _ => out.write_char(character)
      }
    }
  }
  out.to_string()
}

///|
pub fn pointer_decode(pointer : String) -> Array[String] raise DiffError {
  let error = Failure({
    code: InvalidOptions,
    message: "Invalid RFC 6901 string pointer",
    side: Some(Options),
    path: None,
    line: None,
    column: None,
  })
  if pointer == "" {
    return []
  }
  if !pointer.has_prefix("/") {
    raise error
  }
  let result : Array[String] = []
  for segment in pointer[1:].split("/") {
    let chars = segment.iter().to_array()
    let out = StringBuilder()
    let mut i = 0
    while i < chars.length() {
      if chars[i] == '~' {
        i += 1
        if i == chars.length() {
          raise error
        }
        match chars[i] {
          '0' => out.write_char('~')
          '1' => out.write_char('/')
          _ => raise error
        }
      } else {
        out.write_char(chars[i])
      }
      i += 1
    }
    result.push(out.to_string())
  }
  result
}
