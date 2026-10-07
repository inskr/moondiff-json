///|
test "client IO error preserves the exact fixed envelope" {
  assert_eq(
    @bridge.client_error("IO_ERROR", "Could not read input", "old"),
    "{\"schema_version\":\"1.0\",\"ok\":false,\"error\":{\"code\":\"IO_ERROR\",\"message\":\"Could not read input\",\"side\":\"old\",\"path\":null,\"line\":null,\"column\":null}}",
  )
}

///|
test "client encoding and argument errors are MoonBit formatted" {
  assert_eq(
    @report.format_text(
      @bridge.client_error("ENCODING_ERROR", "Invalid UTF-8", "options"),
    ),
    "error: ENCODING_ERROR\nmessage: Invalid UTF-8\nside: \"options\" path: null line: null column: null\n",
  )
  assert_eq(
    @bridge.client_error("INVALID_OPTIONS", "Missing filenames", ""),
    "{\"schema_version\":\"1.0\",\"ok\":false,\"error\":{\"code\":\"INVALID_OPTIONS\",\"message\":\"Missing filenames\",\"side\":null,\"path\":null,\"line\":null,\"column\":null}}",
  )
}

///|
test "client errors quote messages and reject unsupported metadata" {
  let message = "File \"中文\"\nnot readable"
  let encoded = @input.parse_input(
    @bridge.client_error("IO_ERROR", message, "new"),
  )
  match encoded {
    Object(fields) =>
      match fields.get("error") {
        Some(Object(info)) =>
          assert_eq(info.get("message"), Some(Json::string(message)))
        _ => fail("missing error information")
      }
    _ => fail("missing error envelope")
  }
  for pair in [("UNKNOWN", "old"), ("IO_ERROR", "invalid-side")] {
    assert_eq(
      @bridge.client_error(pair.0, "untrusted metadata", pair.1),
      "{\"schema_version\":\"1.0\",\"ok\":false,\"error\":{\"code\":\"INVALID_OPTIONS\",\"message\":\"Invalid client error metadata\",\"side\":null,\"path\":null,\"line\":null,\"column\":null}}",
    )
  }
}
