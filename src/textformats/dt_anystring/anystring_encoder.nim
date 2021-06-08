import json
import ../types / [datatype_definition, textformats_error]
import ../support/json_support

proc anystring_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_string:
    raise newException(EncodingError,
            "Error: value is not a string\n" &
            value.describe_kind & "\n")
  result = value.get_str
  if result.len == 0:
    raise newException(EncodingError,
            "Error: value is an empty string\n")

