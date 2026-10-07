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

///|
pub fn parse_options(text : String) -> Options raise @base.DiffError {
  let value = @input.parse_document(text, @base.Options, @base.default_limits()).root()
  let root = option_object(value, "")
  option_fields(root, ["ignore_paths", "array_rules", "limits"], "")
  let ignore_paths : Array[Array[String]] = []
  let ignores_seen : Map[String, Bool] = Map([])
  match root.get("ignore_paths") {
    None => ()
    Some(Array(paths)) =>
      for i, path in paths {
        let tokens = option_pointer(
          path,
          "/ignore_paths/" + i.to_string(),
          false,
        )
        let encoded = @base.pointer_encode(tokens)
        if !ignores_seen.contains(encoded) {
          ignore_paths.push(tokens)
          ignores_seen[encoded] = true
        }
      }
    _ => raise option_error("/ignore_paths")
  }
  let array_rules : Array[ArrayRule] = []
  let rules_seen : Map[String, Bool] = Map([])
  match root.get("array_rules") {
    None => ()
    Some(Array(rules)) =>
      for i, rule in rules {
        let location = "/array_rules/" + i.to_string()
        let fields = option_object(rule, location)
        option_fields(fields, ["path", "key", "check_order"], location)
        let path = option_pointer(
          option_required(fields, "path", location),
          location + "/path",
          true,
        )
        let key = option_string(
          option_required(fields, "key", location),
          location + "/key",
        )
        let check_order = match fields.get("check_order") {
          None => false
          Some(Boolean(b)) => b
          _ => raise option_error(location + "/check_order")
        }
        let encoded = @base.pointer_encode(path)
        if rules_seen.contains(encoded) {
          raise option_error(location + "/path")
        }
        rules_seen[encoded] = true
        array_rules.push({ path, key, check_order, })
      }
    _ => raise option_error("/array_rules")
  }
  let limits = match root.get("limits") {
    None => @base.default_limits()
    Some(value) => {
      let fields = option_object(value, "/limits")
      option_fields(
        fields,
        ["max_input_bytes", "max_depth", "max_nodes", "max_changes"],
        "/limits",
      )
      @base.Limits::new(
        max_input_bytes=option_limit(fields, "max_input_bytes", 2097152, 1),
        max_depth=option_limit(fields, "max_depth", 64, 0),
        max_nodes=option_limit(fields, "max_nodes", 100000, 1),
        max_changes=option_limit(fields, "max_changes", 10000, 1),
      )
    }
  }
  { ignore_paths, array_rules, limits, }
}

///|
fn option_error(path : String) -> @base.DiffError {
  @base.Failure({
    code: InvalidOptions,
    message: "Invalid options value",
    side: Some(Options),
    path: Some(path),
    line: None,
    column: None,
  })
}

///|
fn option_object(
  value : @input.Value,
  path : String,
) -> Map[String, @input.Value] raise @base.DiffError {
  match value {
    Object(fields) => fields
    _ => raise option_error(path)
  }
}

///|
fn option_fields(
  fields : Map[String, @input.Value],
  allowed : Array[String],
  path : String,
) -> Unit raise @base.DiffError {
  let keys = fields.keys().to_array()
  keys.sort_by(@base.codepoint_compare)
  for key in keys {
    if !allowed.contains(key) {
      raise option_error(path + @base.pointer_encode([key]))
    }
  }
}

///|
fn option_required(
  fields : Map[String, @input.Value],
  key : String,
  path : String,
) -> @input.Value raise @base.DiffError {
  match fields.get(key) {
    Some(value) => value
    None => raise option_error(path + @base.pointer_encode([key]))
  }
}

///|
fn option_string(
  value : @input.Value,
  path : String,
) -> String raise @base.DiffError {
  match value {
    String(s) => s
    _ => raise option_error(path)
  }
}

///|
fn option_pointer(
  value : @input.Value,
  path : String,
  allow_root : Bool,
) -> Array[String] raise @base.DiffError {
  let tokens = @base.pointer_decode(option_string(value, path)) catch {
    @base.Failure(_) => raise option_error(path)
  }
  if !allow_root && tokens.is_empty() {
    raise option_error(path)
  }
  tokens
}

///|
fn option_limit(
  fields : Map[String, @input.Value],
  name : String,
  max : Int,
  min : Int,
) -> Int raise @base.DiffError {
  match fields.get(name) {
    None => max
    Some(Number(_, key)) =>
      match key.bounded_int(max) {
        Some(n) if n >= min => n
        _ => raise option_error("/limits/" + name)
      }
    _ => raise option_error("/limits/" + name)
  }
}
