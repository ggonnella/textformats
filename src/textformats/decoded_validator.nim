import json
import options

import types/datatype_definition
import support/json_support

# modules used in the submodules templates:
import tables
import sequtils
import support/openrange

# forward declaration for submodules procs:
proc is_valid*(item: JsonNode, dd: DatatypeDefinition): bool

# submodules:
import dt_ref/ref_decoded_validator
import dt_anyint/anyint_decoded_validator
import dt_intrange/intrange_decoded_validator
import dt_anyuint/anyuint_decoded_validator
import dt_uintrange/uintrange_decoded_validator
import dt_anyfloat/anyfloat_decoded_validator
import dt_floatrange/floatrange_decoded_validator
import dt_anystring/anystring_decoded_validator
import dt_regexmatch/regexmatch_decoded_validator
import dt_regexesmatch/regexesmatch_decoded_validator
import dt_const/const_decoded_validator
import dt_enum/enum_decoded_validator
import dt_json/json_decoded_validator
import dt_list/list_decoded_validator
import dt_struct/struct_decoded_validator
import dt_dict/dict_decoded_validator
import dt_tags/tags_decoded_validator
import dt_union/union_decoded_validator

proc is_valid*(item: JsonNode, dd: DatatypeDefinition): bool =
  if dd.null_value.is_some and item == dd.null_value.unsafe_get:
    return true
  case dd.kind:
    of ddkRef:           return item.ref_is_valid(dd)
    of ddkAnyInteger:    return item.anyint_is_valid(dd)
    of ddkAnyUInteger:   return item.anyuint_is_valid(dd)
    of ddkAnyFloat:      return item.anyfloat_is_valid(dd)
    of ddkIntRange:      return item.intrange_is_valid(dd)
    of ddkUIntRange:     return item.uintrange_is_valid(dd)
    of ddkFloatRange:    return item.floatrange_is_valid(dd)
    of ddkAnyString:     return item.anystring_is_valid(dd)
    of ddkRegexMatch:    return item.regexmatch_is_valid(dd)
    of ddkRegexesMatch:  return item.regexesmatch_is_valid(dd)
    of ddkConst:         return item.const_is_valid(dd)
    of ddkEnum:          return item.enum_is_valid(dd)
    of ddkJson:          return item.json_is_valid(dd)
    of ddkList:          return item.list_is_valid(dd)
    of ddkStruct:        return item.struct_is_valid(dd)
    of ddkDict:          return item.dict_is_valid(dd)
    of ddkTags:          return item.tags_is_valid(dd)
    of ddkUnion:         return item.union_is_valid(dd)
