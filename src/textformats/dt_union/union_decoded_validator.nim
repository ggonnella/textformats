import json
import sequtils
import ../types/datatype_definition

template union_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool =
  dd.choices.any_it(item.is_valid(it))

