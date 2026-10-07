///|
pub struct Limits {
  max_input_bytes : Int
  max_depth : Int
  max_nodes : Int
  max_changes : Int
}

///|
pub fn default_limits() -> Limits {
  {
    max_input_bytes: 2097152,
    max_depth: 64,
    max_nodes: 100000,
    max_changes: 10000,
  }
}

///|
pub fn Limits::new(
  max_input_bytes? : Int = 2097152,
  max_depth? : Int = 64,
  max_nodes? : Int = 100000,
  max_changes? : Int = 10000,
) -> Limits raise DiffError {
  if max_input_bytes <= 0 ||
    max_input_bytes > 2097152 ||
    max_depth < 0 ||
    max_depth > 64 ||
    max_nodes <= 0 ||
    max_nodes > 100000 ||
    max_changes <= 0 ||
    max_changes > 10000 {
    raise Failure({
      code: InvalidOptions,
      message: "Limits must be positive and cannot exceed defaults (depth may be zero)",
      side: Some(Options),
      path: None,
      line: None,
      column: None,
    })
  }
  { max_input_bytes, max_depth, max_nodes, max_changes, }
}
