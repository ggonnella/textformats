import json
import ../types/datatype_definition
import ../support/json_support

template anyint_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool =
  item.is_int
