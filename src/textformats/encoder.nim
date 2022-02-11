import json, options, strformat, strutils
import support/json_support
import types / [def_syntax, datatype_definition, textformats_error]

# for the as_string option
import decoder

proc encode*(value: JsonNode, dd: DatatypeDefinition): string
proc unsafe_encode*(value: JsonNode, dd: DatatypeDefinition): string
import dt_anyint/anyint_encoder
import dt_intrange/intrange_encoder
import dt_anyuint/anyuint_encoder
import dt_uintrange/uintrange_encoder
import dt_anyfloat/anyfloat_encoder
import dt_floatrange/floatrange_encoder
import dt_anystring/anystring_encoder
import dt_regexmatch/regexmatch_encoder
import dt_regexesmatch/regexesmatch_encoder
import dt_const/const_encoder
import dt_enum/enum_encoder
import dt_list/list_encoder
import dt_struct/struct_encoder
import dt_dict/dict_encoder
import dt_tags/tags_encoder
import dt_union/union_encoder

proc encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if dd.as_string:
    var errmsg = ""
    if not value.is_string:
      raise newException(EncodingError,
              "Error: value is not a string\n" &
              &"but '{AsStringKey}' is true\n" &
              value.describe_kind & "\n")
    try:
      discard value.get_str.decode(dd)
    except DecodingError:
      errmsg = get_current_exception_msg()
    if len(errmsg) > 0:
      raise newException(EncodingError,
              "Error: error validating decoded string\n" &
              &"(with '{AsStringKey}' true):\n" &
              errmsg.indent(2) & "\n")
    return value.get_str
  if dd.kind == ddkRef:
    # handle separately to avoid repeated error messages
    return value.encode(dd.target)
  if dd.null_value.is_some and value == dd.null_value.unsafe_get:
    assert dd.kind != ddkRef
    return ""
  try:
    case dd.kind:
      of ddkRef:                   assert(false) # see above
      of ddkAnyInteger:            return value.anyint_encode(dd)
      of ddkAnyUInteger:           return value.anyuint_encode(dd)
      of ddkAnyFloat:              return value.anyfloat_encode(dd)
      of ddkIntRange:              return value.intrange_encode(dd)
      of ddkUIntRange:             return value.uintrange_encode(dd)
      of ddkFloatRange:            return value.floatrange_encode(dd)
      of ddkAnyString:             return value.anystring_encode(dd)
      of ddkRegexMatch:            return value.regexmatch_encode(dd)
      of ddkRegexesMatch:          return value.regexesmatch_encode(dd)
      of ddkConst:                 return value.const_encode(dd)
      of ddkEnum:                  return value.enum_encode(dd)
      of ddkJson:                  return $value
      of ddkList:                  return value.list_encode(dd)
      of ddkStruct:                return value.struct_encode(dd)
      of ddkDict:                  return value.dict_encode(dd)
      of ddkTags:                  return value.tags_encode(dd)
      of ddkUnion:                 return value.union_encode(dd)
  except EncodingError:
    let e = get_current_exception()
    e.msg = &"Error: invalid value ({value}) for datatype: '{dd.name}':\n" &
            msg.indent(2)
    raise

proc unsafe_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if dd.as_string:              return value.get_str
  if dd.null_value.is_some and value == dd.null_value.unsafe_get: return ""
  case dd.kind:
    of ddkRef:                  return value.unsafe_encode(dd.target)
    of ddkAnyInteger:           return $value.get_biggest_int
    of ddkAnyUInteger:          return $value.get_biggest_int
    of ddkAnyFloat:             return $value.get_float
    of ddkIntRange:             return $value.get_biggest_int
    of ddkUIntRange:            return $value.get_biggest_int
    of ddkFloatRange:           return $value.get_float
    of ddkAnyString:            return value.get_str
    of ddkRegexMatch:           return value.regexmatch_unsafe_encode(dd)
    of ddkRegexesMatch:         return value.regexesmatch_unsafe_encode(dd)
    of ddkConst:                return value.const_unsafe_encode(dd)
    of ddkEnum:                 return value.enum_unsafe_encode(dd)
    of ddkJson:                 return $value
    of ddkList:                 return value.list_unsafe_encode(dd)
    of ddkStruct:               return value.struct_unsafe_encode(dd)
    of ddkDict:                 return value.dict_unsafe_encode(dd)
    of ddkTags:                 return value.tags_unsafe_encode(dd)
    of ddkUnion:                return value.union_unsafe_encode(dd)

