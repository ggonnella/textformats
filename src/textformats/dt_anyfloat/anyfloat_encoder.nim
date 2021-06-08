import json
import ../support/json_support
import ../types / [datatype_definition, textformats_error]

proc anyfloat_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_float:
    raise newException(EncodingError,
            "Error: value is not a float\n" &
            value.describe_kind & "\n")
  return $value.get_float
