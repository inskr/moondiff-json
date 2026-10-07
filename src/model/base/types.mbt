///|
pub(all) enum Side {
  Old
  New
  Options
} derive(Eq, Debug)

///|
pub(all) enum ErrorCode {
  ParseError
  DuplicateKey
  InvalidOptions
  InvalidArrayKey
  InputLimit
  DepthLimit
  NodeLimit
  ChangeLimit
  NumberLimit
  EncodingError
  IoError
} derive(Eq, Debug)

///|
pub(all) struct ErrorInfo {
  code : ErrorCode
  message : String
  side : Side?
  path : String?
  line : Int?
  column : Int?
} derive(Debug)

///|
pub(all) suberror DiffError {
  Failure(ErrorInfo)
} derive(Debug)

///|
pub extend Side with Eq::{equal, not_equal}

///|
pub extend Side with Debug::{to_repr}

///|
pub extend ErrorCode with Eq::{equal, not_equal}

///|
pub extend ErrorCode with Debug::{to_repr}

///|
pub extend ErrorInfo with Debug::{to_repr}

///|
pub extend DiffError with Debug::{to_repr}
