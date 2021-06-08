import json
import ../types/datatype_definition
import ../support/json_support

template anystring_is_valid*(value: JsonNode, dd: DatatypeDefinition): bool =
  value.is_string and value.to(string).len > 0
