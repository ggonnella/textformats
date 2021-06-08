import json
import sequtils
import ../types/datatype_definition
import ../support/json_support

template list_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool =
  if not item.is_array: false
  elif item.len notin dd.lenrange: false
  else: item.get_elems.all_it(it.is_valid(dd.members_def))
