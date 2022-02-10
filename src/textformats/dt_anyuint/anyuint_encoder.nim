import json
import ../support/json_support
import ../types / [datatype_definition, textformats_error]

proc anyuint_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_uint:
    raise newException(EncodingError, "Value is not a non-negative integer, " &
            "found: " & value.describe_kind & "\n")
  return $value.get_biggest_int
