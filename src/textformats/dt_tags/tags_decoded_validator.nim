import json, sets, tables, sequtils
import regex
import ../support/json_support
import ../types/datatype_definition

proc tags_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool
from ../decoded_validator import is_valid

proc tags_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool =
  if not item.is_object: return false
  var implicit = newTable[string, JsonNode]()
  for (name, v) in dd.implicit:
    implicit[name] = v
  for tagname, type_value in item:
    if tagname in implicit:
      if type_value != implicit[tagname]:
        return false
    else:
      if not tagname.match(dd.tagname_regex_compiled): return false
      if not type_value.is_object: return false
      let expected_tags = [dd.type_key, dd.value_key].to_hash_set
      if to_seq(type_value.get_fields.keys).to_hash_set != expected_tags:
        return false
      let typetag = typevalue[dd.type_key]
      if tagname in dd.predefined_tags and dd.predefined_tags[tagname] != typetag:
        return false
      if typetag notin dd.tagtypes: return false
      if not typevalue[dd.value_key].is_valid(dd.tagtypes[typetag]): return false
  return true
