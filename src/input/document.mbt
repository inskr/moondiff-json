///|
/// Typed exact tree. Constructors are read-only outside this package.
pub enum Value {
  Null
  Boolean(Bool)
  Number(String, NumberKey)
  String(String)
  Array(Array[Value])
  Object(Map[String, Value])
}

///|
/// No external literal constructor and no public access to the stored tree.
pub struct Document {
  priv tree : Value
  node_count : Int
}

///|
pub fn parse_document(
  text : String,
  side : @base.Side,
  limits : @base.Limits,
) -> Document raise @base.DiffError {
  if @utf8.encode(text[:]).length() > limits.max_input_bytes {
    raise document_error(InputLimit, side, "Input exceeds UTF-8 byte limit")
  }
  let parsed = parse_input(text, max_depth=limits.max_depth) catch {
    error => {
      let code = match error {
        @moonjson.Repeated(_, _) => @base.DuplicateKey
        @moonjson.TooDeep(_) => @base.DepthLimit
        _ => @base.ParseError
      }
      let spot = error.at()
      raise @base.Failure({
        code,
        message: "Invalid JSON document",
        side: Some(side),
        path: None,
        line: Some(spot.line),
        column: Some(spot.column),
      })
    }
  }
  let counter = { count: 0, }
  let tree = convert_value(parsed, side, limits, counter, 0)
  { tree, node_count: counter.count, }
}

///|
pub fn Document::root(self : Document) -> Value {
  snapshot(self.tree)
}

///|
priv struct NodeCounter {
  mut count : Int
}

///|
fn document_error(
  code : @base.ErrorCode,
  side : @base.Side,
  message : String,
) -> @base.DiffError {
  @base.Failure({
    code,
    message,
    side: Some(side),
    path: None,
    line: None,
    column: None,
  })
}

///|
fn convert_value(
  value : Json,
  side : @base.Side,
  limits : @base.Limits,
  counter : NodeCounter,
  depth : Int,
) -> Value raise @base.DiffError {
  if depth > limits.max_depth {
    raise document_error(
      DepthLimit,
      side,
      "Document exceeds root-zero depth limit",
    )
  }
  counter.count += 1
  if counter.count > limits.max_nodes {
    raise document_error(NodeLimit, side, "Document exceeds node limit")
  }
  match value {
    Json::Null => Value::Null
    Json::True => Value::Boolean(true)
    Json::False => Value::Boolean(false)
    Json::String(text) => Value::String(text)
    Json::Number(_, repr=Some(raw)) => {
      let key = normalize_number(raw) catch {
        @base.Failure(info) =>
          raise @base.Failure({ ..info, side: Some(side), })
      }
      Value::Number(raw, key)
    }
    Json::Number(_, repr=None) =>
      abort("Parser invariant violated: missing original number token")
    Json::Array(values) => {
      let output : Array[Value] = []
      for child in values {
        output.push(convert_value(child, side, limits, counter, depth + 1))
      }
      Value::Array(output)
    }
    Json::Object(members) => {
      let output : Map[String, Value] = Map([])
      for key, child in members {
        output[key] = convert_value(child, side, limits, counter, depth + 1)
      }
      Value::Object(output)
    }
  }
}

///|
fn snapshot(value : Value) -> Value {
  match value {
    Null | Boolean(_) | Number(_, _) | String(_) => value
    Array(values) => Array(values.map(snapshot))
    Object(members) => {
      let output : Map[String, Value] = Map([])
      for key, child in members {
        output[key] = snapshot(child)
      }
      Object(output)
    }
  }
}
