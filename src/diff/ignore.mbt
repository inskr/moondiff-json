///|
priv struct IgnoreNode {
  mut terminal : Bool
  children : Map[String, IgnoreNode]
}

///|
fn new_ignore_node() -> IgnoreNode {
  { terminal: false, children: Map([]), }
}

///|
fn invalid_options(message : String, path : String) -> @base.DiffError {
  @base.Failure({
    code: InvalidOptions,
    message,
    side: Some(Options),
    path: Some(path),
    line: None,
    column: None,
  })
}

///|
/// Validate every rule on both complete snapshots before pruning parent rules.
fn prepare_ignores(
  paths : Array[Array[String]],
  old : @model.Value,
  new : @model.Value,
) -> IgnoreNode raise @base.DiffError {
  let root = new_ignore_node()
  for index, tokens in paths {
    let config_path = "/ignore_paths/" + index.to_string()
    if tokens.is_empty() {
      raise invalid_options("The root cannot be ignored", config_path)
    }
    validate_object_path(tokens, old, config_path)
    validate_object_path(tokens, new, config_path)
    let mut node = root
    for token in tokens {
      let child = match node.children.get(token) {
        Some(child) => child
        None => {
          let child = new_ignore_node()
          node.children[token] = child
          child
        }
      }
      node = child
    }
    node.terminal = true
  }
  root
}

///|
fn validate_object_path(
  tokens : Array[String],
  value : @model.Value,
  config_path : String,
) -> Unit raise @base.DiffError {
  let mut current = Some(value)
  for token in tokens {
    current = match current {
      Some(Object(members)) => members.get(token)
      Some(Array(_)) =>
        raise invalid_options("Object paths cannot enter an array", config_path)
      _ => None
    }
  }
}
