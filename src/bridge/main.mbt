///|
/// Task 1 feasibility diagnostic, NOT the final analyze report protocol.
#export_name("probe_document")
pub fn probe_document(text : String) -> String {
  try {
    let value = @input.parse_input(text)
    @moonjson.dumps(
      Json::object({
        "probe_version": Json::string("1"),
        "ok": Json::boolean(true),
        "json_text": Json::string(@moonjson.dumps(value, sort=true)),
      }),
      sort=true,
    )
  } catch {
    error => {
      let code = match error {
        @moonjson.Repeated(_, _) => "DUPLICATE_KEY"
        @moonjson.TooDeep(_) => "DEPTH_LIMIT"
        _ => "PARSE_ERROR"
      }
      let spot = error.at()
      @moonjson.dumps(
        Json::object({
          "probe_version": Json::string("1"),
          "ok": Json::boolean(false),
          "code": Json::string(code),
          "line": Json::number(spot.line.to_double()),
          "column": Json::number(spot.column.to_double()),
        }),
        sort=true,
      )
    }
  }
}
