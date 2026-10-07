///|
/// Lexicographic Unicode codepoint order, independent of UTF-16 and shortlex.
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

///|
/// Strict JSON quoting only; no document is reparsed and no numeric conversion.
pub fn quote_string(text : String) -> String {
  @moonjson.dumps(Json::string(text))
}

///|
pub fn render_fragment(value : @model.Value) -> String {
  let out = StringBuilder()
  write_fragment(out, value)
  out.to_string()
}

///|
fn write_fragment(out : StringBuilder, value : @model.Value) -> Unit {
  match value {
    Null => out.write_string("null")
    Boolean(b) => out.write_string(if b { "true" } else { "false" })
    Number(raw, _) => out.write_string(raw)
    String(s) => out.write_string(quote_string(s))
    Array(values) => {
      out.write_char('[')
      for i, child in values {
        if i > 0 {
          out.write_char(',')
        }
        write_fragment(out, child)
      }
      out.write_char(']')
    }
    Object(members) => {
      let keys = members.keys().to_array()
      keys.sort_by(codepoint_compare)
      out.write_char('{')
      for i, key in keys {
        if i > 0 {
          out.write_char(',')
        }
        out.write_string(quote_string(key))
        out.write_char(':')
        write_fragment(out, members.get(key).unwrap())
      }
      out.write_char('}')
    }
  }
}
