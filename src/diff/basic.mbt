///|
pub fn diff_documents(
  old : @model.Document,
  new : @model.Document,
  options : @model.Options,
) -> @model.DiffReport raise @base.DiffError {
  // Task 4 replaces this explicit guard; never silently use positional matching.
  if !options.array_rules.is_empty() {
    raise invalid_options(
      "Keyed arrays are not enabled until task 4", "/array_rules",
    )
  }
  let left = old.root()
  let right = new.root()
  let ignores = prepare_ignores(options.ignore_paths, left, right)
  let state = {
    changes: [],
    max_changes: options.limits.max_changes,
    added: 0,
    removed: 0,
    modified: 0,
    ignored: 0,
  }
  compare_values(Some(left), Some(right), "", "", Some(ignores), state)
  @model.Success(
    {
      added: state.added,
      removed: state.removed,
      modified: state.modified,
      reordered: 0,
      ignored_subtrees: state.ignored,
    },
    state.changes,
  )
}

///|
priv struct DiffState {
  changes : Array[@model.Change]
  max_changes : Int
  mut added : Int
  mut removed : Int
  mut modified : Int
  mut ignored : Int
}

///|
fn slot(value : @model.Value?) -> @model.ValueSlot {
  match value {
    None => @model.ValueSlot::absent()
    Some(value) =>
      @model.ValueSlot::present_json(@report.render_fragment(value))
  }
}

///|
fn add_change(
  kind : @model.ChangeKind,
  old : @model.Value?,
  new : @model.Value?,
  old_path : String,
  new_path : String,
  state : DiffState,
) -> Unit raise @base.DiffError {
  if state.changes.length() >= state.max_changes {
    raise @base.Failure({
      code: ChangeLimit,
      message: "Difference exceeds change limit",
      side: None,
      path: None,
      line: None,
      column: None,
    })
  }
  state.changes.push({
    kind,
    old_path: if old is None {
      None
    } else {
      Some(old_path)
    },
    new_path: if new is None {
      None
    } else {
      Some(new_path)
    },
    before: slot(old),
    after: slot(new),
    identity: None,
  })
  match kind {
    Added => state.added += 1
    Removed => state.removed += 1
    Modified => state.modified += 1
    Reordered => abort("Invariant: basic diff cannot reorder")
  }
}

///|
fn compare_values(
  old : @model.Value?,
  new : @model.Value?,
  old_path : String,
  new_path : String,
  ignores : IgnoreNode?,
  state : DiffState,
) -> Unit raise @base.DiffError {
  if ignores is Some({ terminal: true, .. }) {
    state.ignored += 1
    return
  }
  match (old, new) {
    (None, None) => ()
    (None, Some(_)) => add_change(Added, old, new, old_path, new_path, state)
    (Some(_), None) => add_change(Removed, old, new, old_path, new_path, state)
    (Some(Object(left)), Some(Object(right))) => {
      let keys = left.keys().to_array()
      for key, _ in right {
        if !left.contains(key) {
          keys.push(key)
        }
      }
      keys.sort_by(@report.codepoint_compare)
      for key in keys {
        let child_ignore = match ignores {
          Some(node) => node.children.get(key)
          None => None
        }
        let suffix = pointer_encode([key])
        compare_values(
          left.get(key),
          right.get(key),
          old_path + suffix,
          new_path + suffix,
          child_ignore,
          state,
        )
      }
    }
    (Some(Array(left)), Some(Array(right))) => {
      let length = if left.length() > right.length() {
        left.length()
      } else {
        right.length()
      }
      for i in 0..<length {
        let a = if i < left.length() { Some(left[i]) } else { None }
        let b = if i < right.length() { Some(right[i]) } else { None }
        let suffix = "/" + i.to_string()
        compare_values(a, b, old_path + suffix, new_path + suffix, None, state)
      }
    }
    (Some(Null), Some(Null)) => ()
    (Some(Boolean(a)), Some(Boolean(b))) if a == b => ()
    (Some(String(a)), Some(String(b))) if a == b => ()
    (Some(Number(_, a)), Some(Number(_, b))) if a == b => ()
    _ => add_change(Modified, old, new, old_path, new_path, state)
  }
}
