import json
import sets
import ../types/datatype_definition

proc nonmember_keys_valid*(item: JsonNode, item_keys: var HashSet[string],
                              dd: DatatypeDefinition): bool =
  if item_keys.len > 0:
    for member in dd.implicit:
      if member.name in item_keys:
        if item[member.name] != member.value:
          return false
        item_keys.excl(member.name)
  return item_keys.len == 0
