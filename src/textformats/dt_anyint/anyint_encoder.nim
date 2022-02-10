import json
import ../support/json_support
import ../types / [datatype_definition, textformats_error]

proc anyint_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_int:
    raise newException(EncodingError, "Value is not an integer, found: " &
            value.describe_kind & "\n")
  return $value.get_biggest_int
