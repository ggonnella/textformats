import json
import sets
import tables
import sequtils
import ../types/datatype_definition
import ../support/json_support
import ../shared/implicit_decoded_validator

proc dict_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool
from ../decoded_validator import is_valid

proc dict_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool =
  if not item.is_object: return false
  var item_keys = to_seq(item.get_fields.keys).toHashSet
  for name, def in dd.dict_members:
    if name notin item_keys and name in dd.required_keys:
      return false
    if name in dd.single_keys:
      if not item[name].is_valid(def):
        return false
    else:
      for subelem in item[name]:
        if not subelem.is_valid(def):
          return false
    item_keys.excl(name)
  return item.nonmember_keys_valid(item_keys, dd)
