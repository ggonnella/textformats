import strutils, strformat, options, json
import regex
import types / [datatype_definition, textformats_error, lines_reader]

proc decode*(input: string, dd: DatatypeDefinition): JsonNode

proc prematched_decode*(input: string,
                        slice: Slice[int],
                        dd: DatatypeDefinition,
                        m: RegexMatch,
                        childnum: int,
                        groupspfx: string): JsonNode

proc decode_multiline*(ls: var LinesReader, dd: DatatypeDefinition): JsonNode

proc decode_multiline_lines*(ls: var LinesReader, dd: DatatypeDefinition,
                             action: proc(j: JsonNode))

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

template raise_decoding_error(input: string, msg: string,
                              dd: DatatypeDefinition) =
  var smsg = msg
  smsg = smsg.strip(leading=false)
  smsg.stripLineEnd()
  raise newException(DecodingError,
                     "Error: invalid encoded string according to datatype\n" &
                     "Datatype name: " & dd.name & "\n" &
                     "Encoded string: '" & $input & "'\n" &
                     smsg.indent(2))

proc prematched_decode*(input: string, slice: Slice[int],
                 dd: DatatypeDefinition, m: RegexMatch, childnum: int,
                 groupspfx: string): JsonNode =
  let sliced = if input.len > 0 and slice.b >= 0: input[slice] else: input
  if dd.kind == ddkRef:
    result = input.prematched_decode(slice, dd.target, m, childnum, groupspfx)
  else:
    if sliced.len == 0 and dd.null_value.is_some:
      result = dd.null_value.unsafe_get
    elif not dd.regex.ensures_valid:
      result = sliced.decode(dd)
    else:
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

proc decode*(input: string, dd: DatatypeDefinition): JsonNode =
  if input.len == 0 and dd.null_value.is_some:
    assert dd.kind != ddkRef
    result = dd.null_value.unsafe_get
  else:
    try:
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
      let e = get_current_exception()
      raise_decoding_error(input, e.msg, dd)
  return if dd.as_string: %input else: result

template open_input_file(filename: string): File =
  var file: File = nil
  try: file = open(filename)
  except IOError:
    let e = getCurrentException()
    raise newException(TextformatsRuntimeError,
                       "Error while reading input file '" & filename &
                       "'\n" & e.msg)
  file

type
  dataParsingState = enum
    dpsPre, dpsYaml, dpsData

iterator decoded_lines*(filename: string, dd: DatatypeDefinition,
                       embedded = false, wrapped = false,
                       group_by = 1): JsonNode =
  ##
  ## Decode a file applying the definition dd to each line independently
  ##
  ## if embedded is set to true, the file is assumed to contain an
  ## embedded specification in the header, which is skipped; i.e. only
  ## the content after the first document separator --- is analyzed
  ##
  ## if wrapped is true, then, if the definition is a union, then the
  ## definition wrapped flag is set
  ##
  assert group_by >= 1
  let file = open_input_file(filename)
  var def = dd
  if wrapped and dd.kind == ddkUnion:
    def.wrapped = true
  var
    line_no = 0
    state = if embedded: dpsPre else: dpsData
    linesgroup = newseq[string](group_by)
    n_in_group = 0
    shall_decode = true
  for line in lines(file):
    line_no += 1
    case state:
    of dpsData:
      if group_by > 1:
        linesgroup[n_in_group] = line
        n_in_group += 1
        shall_decode = (n_in_group == group_by)
      if shall_decode:
        try:
          if group_by > 1:
            yield linesgroup.join("\n").decode(def)
            n_in_group = 0
          else:
            yield line.decode(def)
        except DecodingError:
          var msg = &"File: '{filename}'\n" &
                    &"Line number: {line_no}\n"
          raise newException(DecodingError, msg & getCurrentExceptionMsg())
    of dpsPre:
      let uncommented = line.split("#")[0]
      if len(uncommented.strip) > 0:
        state = dpsYaml
    of dpsYaml:
      if line == "---":
        state = dpsData
  if n_in_group > 0:
    raise newException(DecodingError,
                       &"File: '{filename}'\n" &
                       "Final group of lines does not contain enough lines\n" &
                       &"Found n. of lines: {n_in_group}\n" &
                       &"Required n. of lines: {group_by}")

proc decode_multiline*(ls: var LinesReader, dd: DatatypeDefinition): JsonNode =
  if dd.kind == ddkRef:
    return ls.decode_multiline(dd.target)
  if dd.sep == "\n":
    try:
      case dd.kind:
      of ddkStruct: result = ls.decode_multiline_struct(dd)
      of ddkList:   result = ls.decode_multiline_list(dd)
      of ddkDict:   result = ls.decode_multiline_dict(dd)
      #of ddkTags:   result = ls.decode_multiline_tags(dd)
      else: assert(false)
    except DecodingError:
      raise_decoding_error(ls.line, get_current_exception_msg(), dd)
  else:
    result = ls.line.decode(dd)
    ls.consume

proc validate_unit_definition(dd: DatatypeDefinition) =
  if dd.kind != ddkStruct:
    raise newException(TextformatsRuntimeError,
            "Wrong datatype definition for multiline unit decoder\n" &
            "Expected: structure (kind: ddkStruct)\n" &
            &"Found: '{dd.kind}'")
  if dd.sep != "\n":
    raise newException(TextformatsRuntimeError,
            "Wrong separator for multiline unit decoder\n" &
            "Expected: newline\n" &
            &"Found: '{dd.sep}'")
  if dd.pfx.len > 0:
    raise newException(TextformatsRuntimeError,
            "Wrong prefix for multipline unit decoder\n" &
            "Expected: empty string\n" &
            &"Found: '{dd.pfx}'")
  if dd.sfx.len > 0:
    raise newException(TextformatsRuntimeError,
            "Wrong suffix for multipline unit decoder\n" &
            "Expected: empty string\n" &
            &"Found: '{dd.sfx}'")

iterator decode_units*(filename: string, dd: DatatypeDefinition): JsonNode =
  ##
  ## Decode a file as a list of multi-line units.
  ## The dd must be a ddkStruct definition or a ref to a ddkStruct
  ## with a "\n" separator, and no pfx or sfx.
  ##
  let file = open_input_file(filename)
  var ddef = dd
  while ddef.kind == ddkRef:
    assert(not ddef.target.is_nil)
    ddef = ddef.target
  ddef.validate_unit_definition
  var ls = new_lines_reader(file)
  while not ls.eof:
    yield ls.decode_multiline(ddef)

proc decode_multiline_lines*(ls: var LinesReader, dd: DatatypeDefinition,
                             action: proc(j: JsonNode)) =
  if dd.kind == ddkRef:
    ls.decode_multiline_lines(dd.target, action)
  if dd.sep == "\n":
    try:
      case dd.kind:
      of ddkStruct: ls.decode_multiline_struct_lines(dd, action)
      of ddkList:   ls.decode_multiline_list_lines(dd, action)
      of ddkDict:   ls.decode_multiline_dict_lines(dd, action)
      #of ddkTags:   ls.decode_multiline_tags(dd, action)
      else: assert(false)
    except DecodingError:
      raise_decoding_error(ls.line, get_current_exception_msg(), dd)
  else:
    action(ls.line.decode(dd))
    ls.consume

proc decode_file_linewise*(filename: string, dd: DatatypeDefinition,
                           action: proc(j: JsonNode)) =
  let file = open_input_file(filename)
  var ddef = dd
  while ddef.kind == ddkRef:
    assert(not ddef.target.is_nil)
    ddef = ddef.target
  ddef.validate_unit_definition
  var ls = new_lines_reader(file)
  while not ls.eof:
    decode_multiline_lines(ls, ddef, action)
