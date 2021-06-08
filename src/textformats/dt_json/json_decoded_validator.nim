import json
import ../types/datatype_definition

template json_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool =
  true
