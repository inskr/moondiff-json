///|
/// Strict parsing adapter. The dependency enforces depth during parsing,
/// with the root at depth zero. Numeric consumers MUST use Number.repr;
/// neither Json's Eq implementation nor its Double payload is exact.
/// Document, side and remaining limits are introduced in tasks 2 and 5.
pub fn parse_input(
  text : String,
  max_depth? : Int = 64,
) -> Json raise @moonjson.Malformed {
  let source = if text.has_prefix("\u{FEFF}") { text[1:] } else { text[:] }
  @moonjson.loads(source, {
    ..@moonjson.strict,
    duplicates: Reject,
    depth: max_depth,
  })
}
