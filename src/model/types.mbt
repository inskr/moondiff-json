///|
pub using @base {
  type Side,
  type Limits,
  type ErrorCode,
  type ErrorInfo,
  type DiffError,
  default_limits,
}

///|
pub using @input {
  type Document,
  type Value,
  type NumberKey,
  parse_document,
  normalize_number,
}

///|
pub struct ValueSlot {
  present : Bool
  json_text : String?
}

///|
pub fn ValueSlot::absent() -> ValueSlot {
  { present: false, json_text: None, }
}

///|
pub fn ValueSlot::present_json(json_text : String) -> ValueSlot {
  { present: true, json_text: Some(json_text), }
}

///|
pub(all) enum ChangeKind {
  Added
  Removed
  Modified
  Reordered
}

///|
pub(all) struct Identity {
  array_old_path : String?
  array_new_path : String?
  key : String
  value_json : String
}

///|
pub(all) struct Change {
  kind : ChangeKind
  old_path : String?
  new_path : String?
  before : ValueSlot
  after : ValueSlot
  identity : Identity?
}

///|
pub(all) struct Summary {
  added : Int
  removed : Int
  modified : Int
  reordered : Int
  ignored_subtrees : Int
}

///|
pub(all) enum DiffReport {
  Success(Summary, Array[Change])
  Error(@base.ErrorInfo)
}
