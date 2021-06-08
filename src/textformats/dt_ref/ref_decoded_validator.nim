import json
import ../types/datatype_definition
import ../decoded_validator

template ref_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool =
  item.is_valid(dd.target)
