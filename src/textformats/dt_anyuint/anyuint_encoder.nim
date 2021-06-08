import json
import ../support/json_support
import ../types / [datatype_definition, textformats_error]

proc anyuint_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_uint:
    raise newException(EncodingError,
            "Error: value is not a non-negative integer\n" &
            value.describe_kind & "\n")
  return $value.get_int
