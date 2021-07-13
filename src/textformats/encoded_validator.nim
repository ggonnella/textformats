import options
import regex
import types/datatype_definition
import support/openrange

proc is_valid*(input: string, dd: DatatypeDefinition): bool
import dt_floatrange/floatrange_encoded_validator
import dt_uintrange/uintrange_encoded_validator
import dt_anystring/anystring_encoded_validator
import dt_const/const_encoded_validator
import dt_enum/enum_encoded_validator
import dt_json/json_encoded_validator
import dt_list/list_encoded_validator
import dt_struct/struct_encoded_validator
import dt_dict/dict_encoded_validator
import dt_tags/tags_encoded_validator
import dt_union/union_encoded_validator

proc is_valid*(input: string, dd: DatatypeDefinition): bool =
  if dd.kind == ddkRef:
    assert(not dd.target.is_nil)
    return input.is_valid(dd.target)
  if input.len == 0 and dd.null_value.is_some:
    assert dd.kind != ddkRef
    return true
  if dd.kind == ddkAnyString: return input.anystring_is_valid(dd)
  if dd.regex.ensures_valid:  return input.match(dd.regex.compiled)
  case dd.kind:
  of ddkUintRange:  return input.uintrange_is_valid(dd)
  of ddkFloatRange: return input.floatrange_is_valid(dd)
  of ddkConst:      return input.const_is_valid(dd)
  of ddkEnum:       return input.enum_is_valid(dd)
  of ddkJson:       return input.json_is_valid(dd)
  of ddkList:       return input.list_is_valid(dd)
  of ddkStruct:     return input.struct_is_valid(dd)
  of ddkDict:       return input.dict_is_valid(dd)
  of ddkTags:       return input.tags_is_valid(dd)
  of ddkUnion:      return input.union_is_valid(dd)
  else: assert(false)
