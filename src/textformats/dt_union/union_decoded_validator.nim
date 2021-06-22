import json, sets, tables, sequtils
import ../types/datatype_definition
import ../support/json_support

proc union_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool
from ../decoded_validator import is_valid

proc union_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool =
  if dd.wrapped:
    if item.is_object:
      let keys = to_seq(item.get_fields.keys).to_hash_set()
      if len(keys) == 2 and "type" in keys and "value" in keys:
        let i = dd.type_labels.find(item["type"])
        if i == -1:
          return false
        else:
          return item["value"].is_valid(dd.choices[i])
      else:
        return false
    else:
      return false
  else:
    return dd.choices.any_it(item.is_valid(it))

