import strutils, strformat, options, json
import regex
import types / [datatype_definition, textformats_error]

proc decode*(input: string, dd: DatatypeDefinition): JsonNode

proc prematched_decode*(input: string,
                        slice: Slice[int],
                        dd: DatatypeDefinition,
                        m: RegexMatch,
                        childnum: int,
                        groupspfx: string): JsonNode

# special values of childnum:
const
  NoChildNum* = -1      # not under a list
  UnknownChildNum* = -2 # under union or a nested list

import dt_anyint/anyint_decoder
import dt_intrange/intrange_decoder
import dt_anyuint/anyuint_decoder
import dt_uintrange/uintrange_decoder
import dt_anyfloat/anyfloat_decoder
import dt_floatrange/floatrange_decoder
import dt_anystring/anystring_decoder
import dt_regexmatch/regexmatch_decoder
import dt_regexesmatch/regexesmatch_decoder
import dt_const/const_decoder
import dt_enum/enum_decoder
import dt_json/json_decoder
import dt_list/list_decoder
import dt_struct/struct_decoder
import dt_dict/dict_decoder
import dt_tags/tags_decoder
import dt_union/union_decoder

template reraise_decoding_error*(input: string,
                               dd: DatatypeDefinition) =
  let e = get_current_exception()
  e.msg = e.msg.strip(leading=false)
  e.msg.stripLineEnd()
  e.msg = "Invalid encoded string for datatype '" & dd.name &
          "': " & $input & "\n" & e.msg.indent(2)
  raise

proc prematched_decode*(input: string, slice: Slice[int],
                 dd: DatatypeDefinition, m: RegexMatch, childnum: int,
                 groupspfx: string): JsonNode =
  ##
  ## (for internal use, see decode)
  ##
  let sliced = if input.len > 0 and slice.b >= 0: input[slice] else: input
  if dd.kind == ddkRef:
    result = input.prematched_decode(slice, dd.target, m, childnum, groupspfx)
  else:
    if sliced.len == 0 and dd.null_value.is_some:
      result = dd.null_value.unsafe_get
    elif not dd.regex.ensures_valid:
      result = sliced.decode(dd)
    else:
      if dd.as_string:
        result = %sliced
      # the following should never raise exceptions, since the input is
      # already validated by the regular expression
      case dd.kind:
      of ddkAnyInteger:   result = sliced.decode_anyint(dd)
      of ddkAnyUInteger:  result = sliced.decode_anyuint(dd)
      of ddkIntRange:     result = sliced.decode_intrange(dd)
      of ddkUIntRange:    result = sliced.decode_uintrange(dd)
      of ddkAnyFloat:     result = sliced.decode_anyfloat(dd)
      of ddkAnyString:    result = sliced.decode_anystring(dd)
      of ddkRegexMatch:   result = input.prematched_decode_regexmatch(
                                   slice, dd, m, childnum, groupspfx)
      of ddkRegexesMatch: result = input.prematched_decode_regexesmatch(
                                   slice, dd, m, childnum, groupspfx)
      of ddkConst:        result = input.prematched_decode_const(
                                   slice, dd, m, childnum, groupspfx)
      of ddkEnum:         result = input.prematched_decode_enum(
                                   slice, dd, m, childnum, groupspfx)
      of ddkList:         result = input.prematched_decode_list(
                                   slice, dd, m, childnum, groupspfx)
      of ddkStruct:       result = input.prematched_decode_struct(
                                   slice, dd, m, childnum, groupspfx)
      of ddkUnion:        result = input.prematched_decode_union(
                                   slice, dd, m, childnum, groupspfx)
      else: assert(false)
  return if dd.as_string: %sliced else: result

proc decode_as_string_by_regex*(input: string, dd: DatatypeDefinition):
                                JsonNode =
  assert dd.as_string
  when defined(trace_regex):
    debugEcho("trace_regex|decode|as_string|match(r)|" & dd.name)
  if input.match(dd.regex.compiled):
    return input.translated(dd)
  else:
    raise newException(DecodingError,
             &"Regular expression not matching: {dd.regex.raw}\n")

proc decode*(input: string, dd: DatatypeDefinition): JsonNode
            {.raises: [DecodingError].} =
  if input.len == 0 and dd.null_value.is_some:
    assert dd.kind != ddkRef
    result = dd.null_value.unsafe_get
  else:
    try:
      if dd.as_string and dd.regex.ensures_valid:
        return input.decode_as_string_by_regex(dd)
      case dd.kind:
      of ddkRef:
        assert(not dd.target.is_nil)
        result = input.decode(dd.target)
      of ddkAnyInteger:    result = input.decode_anyint(dd)
      of ddkAnyUInteger:   result = input.decode_anyuint(dd)
      of ddkIntRange:      result = input.decode_intrange(dd)
      of ddkUIntRange:     result = input.decode_uintrange(dd)
      of ddkAnyFloat:      result = input.decode_anyfloat(dd)
      of ddkFloatRange:    result = input.decode_floatrange(dd)
      of ddkAnyString:     result = input.decode_anystring(dd)
      of ddkRegexesMatch:  result = input.decode_regexesmatch(dd)
      of ddkRegexMatch:    result = input.decode_regexmatch(dd)
      of ddkConst:         result = input.decode_const(dd)
      of ddkEnum:          result = input.decode_enum(dd)
      of ddkJson:          result = input.decode_json(dd)
      of ddkList:          result = input.decode_list(dd)
      of ddkStruct:        result = input.decode_struct(dd)
      of ddkDict:          result = input.decode_dict(dd)
      of ddkTags:          result = input.decode_tags(dd)
      of ddkUnion:         result = input.decode_union(dd)
    except DecodingError:
      reraise_decoding_error(input, dd)
  return if dd.as_string: %input else: result

