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

///|
#export_name("analyze")
pub fn analyze(
  old_text : String,
  new_text : String,
  options_text : String,
) -> String {
  let report = try {
    let options = @model.parse_options(options_text)
    let old = @input.parse_document(old_text, @base.Old, options.limits)
    let new = @input.parse_document(new_text, @base.New, options.limits)
    @diff.diff_documents(old, new, options)
  } catch {
    @base.Failure(info) => @model.Error(info)
  }
  @report.render_json(report)
}

///|
#export_name("format_text")
pub fn format_text(text : String) -> String {
  @report.format_text(text) catch {
    @base.Failure(info) =>
      throw_format_error(@report.render_json(@model.Error(info)))
  }
}

///|
/// Only JS exception transport; all validation and report bytes stay in MoonBit.
extern "js" fn throw_format_error(report_text : String) -> String =
  #| function(reportText) {
  #|   const error = new Error(reportText);
  #|   error.name = "MoonDiffFormatError";
  #|   error.report_text = reportText;
  #|   throw error;
  #| }
