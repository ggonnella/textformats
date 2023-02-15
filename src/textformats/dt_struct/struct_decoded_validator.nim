import sets, tables, sequtils, json
import ../types/datatype_definition
import ../support/json_support
import ../shared/implicit_decoded_validator
import struct_nesting

proc struct_is_valid*(value: JsonNode, dd: DatatypeDefinition): bool
from ../decoded_validator import is_valid

proc struct_is_valid*(value: JsonNode, dd: DatatypeDefinition): bool =
  if not value.is_object: return false
  var
    nvalue1 = if (dd.merge_keys.len > 0): value.pass_keys_to_children(dd)
              else: value
    nvalue = if dd.combine_nested: nvalue1.normalize_struct_values()
             else: nvalue1
    value_keys = to_seq(nvalue.get_fields.keys).toHashSet
    i = 0
  for (name, subdef) in dd.members:
    if i notin dd.hidden:
      if name notin value_keys:
        if i < dd.n_required:
          return false
        else:
          for j in i..<dd.members.len:
            let optname = dd.members[j].name
            if optname in value_keys:
              return false
          break
      elif not nvalue[name].is_valid(subdef):
        return false
    value_keys.excl(name)
    i += 1
  return nvalue.nonmember_keys_valid(value_keys, dd)
