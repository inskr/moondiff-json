///|
/// Paths contain decoded RFC 6901 tokens; validation is added in tasks 3–5.
pub(all) struct ArrayRule {
  path : Array[String]
  key : String
  check_order : Bool
}

///|
pub(all) struct Options {
  ignore_paths : Array[Array[String]]
  array_rules : Array[ArrayRule]
  limits : @base.Limits
}

///|
pub fn Options::default() -> Options {
  { ignore_paths: [], array_rules: [], limits: @base.default_limits(), }
}
