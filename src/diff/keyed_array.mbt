///|
priv struct KeyedEntry {
  index : Int
  value : @model.Value
  identity_json : String
}

///|
priv struct KeyedIndex {
  entries : Map[String, KeyedEntry]
  order : Array[String]
}

///|
priv struct KeyedArray {
  rule : @model.ArrayRule
  old : KeyedIndex?
  new : KeyedIndex?
}

///|
fn ignore_covers(root : IgnoreNode, tokens : Array[String]) -> Bool {
  let mut node = root
  for token in tokens {
    if node.terminal {
      return true
    }
    match node.children.get(token) {
      Some(child) => node = child
      None => return false
    }
  }
  node.terminal
}

///|
fn resolve_rule(
  tokens : Array[String],
  value : @model.Value,
  config_path : String,
) -> @model.Value? raise @base.DiffError {
  let mut current = Some(value)
  for token in tokens {
    current = match current {
      Some(Object(members)) => members.get(token)
      Some(Array(_)) =>
        raise invalid_options(
          "Array rules cannot enter another array", config_path,
        )
      _ => None
    }
  }
  current
}

///|
fn rule_values(
  value : @model.Value?,
  config_path : String,
) -> Array[@model.Value]? raise @base.DiffError {
  match value {
    None => None
    Some(Array(values)) => Some(values)
    _ =>
      raise invalid_options(
        "An existing array rule target must be an array", config_path,
      )
  }
}

///|
/// Validate configuration before data; preindex even arrays below added ancestors.
fn prepare_keyed(
  rules : Array[@model.ArrayRule],
  old : @model.Value,
  new : @model.Value,
  ignores : IgnoreNode,
) -> Map[String, KeyedArray] raise @base.DiffError {
  let seen : Map[String, Bool] = Map([])
  for i, rule in rules {
    let path = pointer_encode(rule.path)
    if seen.contains(path) {
      raise invalid_options(
        "Duplicate array rule path",
        "/array_rules/" + i.to_string() + "/path",
      )
    }
    seen[path] = true
  }
  let result : Map[String, KeyedArray] = Map([])
  for i, rule in rules {
    // Complete input validation has already happened at Document construction.
    if ignore_covers(ignores, rule.path) {
      continue
    }
    let config_path = "/array_rules/" + i.to_string() + "/path"
    let left = rule_values(
      resolve_rule(rule.path, old, config_path),
      config_path,
    )
    let right = rule_values(
      resolve_rule(rule.path, new, config_path),
      config_path,
    )
    if left is None && right is None {
      raise invalid_options(
        "Array rule target is absent on both sides", config_path,
      )
    }
    let path = pointer_encode(rule.path)
    let left_index = match left {
      Some(values) => Some(index_identities(values, rule.key, path, Old))
      None => None
    }
    let right_index = match right {
      Some(values) => Some(index_identities(values, rule.key, path, New))
      None => None
    }
    result[path] = { rule, old: left_index, new: right_index, }
  }
  result
}

///|
fn identity_error(
  side : @base.Side,
  array_path : String,
  index : Int,
  key : String,
  reason : String,
) -> @base.DiffError {
  @base.Failure({
    code: InvalidArrayKey,
    message: reason +
    " at array " +
    @report.quote_string(array_path) +
    ", index " +
    index.to_string(),
    side: Some(side),
    path: Some(array_path + "/" + index.to_string() + pointer_encode([key])),
    line: None,
    column: None,
  })
}

///|
fn identity_key(value : @model.Value) -> String? {
  match value {
    String(s) => Some("S:" + s)
    Number(_, key) if key.is_integer() =>
      Some(
        "N:" +
        (if key.negative { "-" } else { "+" }) +
        ":" +
        key.digits +
        ":" +
        key.exponent.to_string(),
      )
    _ => None
  }
}

///|
fn index_identities(
  values : Array[@model.Value],
  key : String,
  array_path : String,
  side : @base.Side,
) -> KeyedIndex raise @base.DiffError {
  let entries : Map[String, KeyedEntry] = Map([])
  let order : Array[String] = []
  for index, value in values {
    let identity = match value {
      Object(members) =>
        match members.get(key) {
          Some(identity) => identity
          None =>
            raise identity_error(
              side, array_path, index, key, "Missing identity property",
            )
        }
      _ =>
        raise identity_error(
          side, array_path, index, key, "Array element must be an object",
        )
    }
    let sort_key = match identity_key(identity) {
      Some(sort_key) => sort_key
      None =>
        raise identity_error(
          side, array_path, index, key, "Identity must be a string or exact integer",
        )
    }
    if entries.contains(sort_key) {
      raise identity_error(side, array_path, index, key, "Duplicate identity")
    }
    entries[sort_key] = {
      index,
      value,
      identity_json: @report.render_fragment(identity),
    }
    order.push(sort_key)
  }
  { entries, order, }
}

///|
fn shared_sequence(keys : Array[String], index : KeyedIndex) -> String {
  let out = StringBuilder()
  out.write_char('[')
  for i, key in keys {
    if i > 0 {
      out.write_char(',')
    }
    out.write_string(index.entries.get(key).unwrap().identity_json)
  }
  out.write_char(']')
  out.to_string()
}

///|
fn compare_keyed(
  keyed : KeyedArray,
  old_path : String,
  new_path : String,
  state : DiffState,
) -> Unit raise @base.DiffError {
  // Only reached for two present arrays. Whole-array adds/removes use basic diff.
  let left = keyed.old.unwrap()
  let right = keyed.new.unwrap()
  if keyed.rule.check_order {
    let old_shared = left.order.filter(key => right.entries.contains(key))
    let new_shared = right.order.filter(key => left.entries.contains(key))
    if old_shared != new_shared {
      push_change(
        {
          kind: Reordered,
          old_path: Some(old_path),
          new_path: Some(new_path),
          before: @model.ValueSlot::present_json(
            shared_sequence(old_shared, left),
          ),
          after: @model.ValueSlot::present_json(
            shared_sequence(new_shared, right),
          ),
          identity: None,
        },
        state,
      )
    }
  }
  let keys = left.entries.keys().to_array()
  for key, _ in right.entries {
    if !left.entries.contains(key) {
      keys.push(key)
    }
  }
  keys.sort_by(@report.codepoint_compare)
  for key in keys {
    let old = left.entries.get(key)
    let new = right.entries.get(key)
    // For shared identities use the old token; for additions use the new token.
    let representative = match old {
      Some(entry) => entry
      None => new.unwrap()
    }
    let identity : @model.Identity? = Some({
      array_old_path: Some(old_path),
      array_new_path: Some(new_path),
      key: keyed.rule.key,
      value_json: representative.identity_json,
    })
    let old_child = match old {
      Some(entry) => old_path + "/" + entry.index.to_string()
      None => old_path
    }
    let new_child = match new {
      Some(entry) => new_path + "/" + entry.index.to_string()
      None => new_path
    }
    compare_values(
      old.map(e => e.value),
      new.map(e => e.value),
      old_child,
      new_child,
      None,
      state,
      identity~,
    )
  }
}
