import json, tables, sequtils
import ../types/datatype_definition
import ../support/json_support

proc union_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool
from ../decoded_validator import is_valid

proc union_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool =
  if dd.wrapped:
    if item.is_object:
      if len(item) != 1: return false
      let
        branch_name= to_seq(item.get_fields.keys)[0]
        i = dd.branch_names.find(branch_name)
      return if i == -1: false else: item[branch_name].is_valid(dd.choices[i])
    else:
      return false
  else:
    return dd.choices.any_it(item.is_valid(it))

