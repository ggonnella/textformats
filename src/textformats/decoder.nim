import strutils, strformat, options, json
import regex
import types / [datatype_definition, textformats_error,
                def_syntax, lines_reader]

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

proc prematched_decode(input: string, slice: Slice[int],
                 dd: DatatypeDefinition, m: RegexMatch, childnum: int,
                 groupspfx: string): JsonNode =
  if dd.kind == ddkRef:
    return input.prematched_decode(slice, dd.target, m, childnum, groupspfx)
  else:
    let sliced = if input.len > 0 and slice.b >= 0: input[slice] else: input
    if sliced.len == 0 and dd.null_value.is_some:
      return dd.null_value.unsafe_get
    if not dd.regex.ensures_valid:
      return sliced.decode(dd)
    # the following should never raise exceptions, since the input is
    # already validated by the regular expression
    case dd.kind:
    of ddkAnyInteger:   return sliced.decode_anyint(dd)
    of ddkAnyUInteger:  return sliced.decode_anyuint(dd)
    of ddkIntRange:     return sliced.decode_intrange(dd)
    of ddkUIntRange:    return sliced.decode_uintrange(dd)
    of ddkAnyFloat:     return sliced.decode_anyfloat(dd)
    of ddkAnyString:    return sliced.decode_anystring(dd)
    of ddkRegexMatch:   return input.prematched_decode_regexmatch(
                                 slice, dd, m, childnum, groupspfx)
    of ddkRegexesMatch: return input.prematched_decode_regexesmatch(
                                 slice, dd, m, childnum, groupspfx)
    of ddkConst:        return input.prematched_decode_const(
                                 slice, dd, m, childnum, groupspfx)
    of ddkEnum:         return input.prematched_decode_enum(
                                 slice, dd, m, childnum, groupspfx)
    of ddkList:         return input.prematched_decode_list(
                                 slice, dd, m, childnum, groupspfx)
    of ddkStruct:       return input.prematched_decode_struct(
                                 slice, dd, m, childnum, groupspfx)
    of ddkUnion:        return input.prematched_decode_union(
                                 slice, dd, m, childnum, groupspfx)
    else: assert(false)

proc decode*(input: string, dd: DatatypeDefinition): JsonNode =
  if input.len == 0 and dd.null_value.is_some:
    assert dd.kind != ddkRef
    return dd.null_value.unsafe_get
  try:
    case dd.kind:
    of ddkRef:
      assert(not dd.target.is_nil)
      return input.decode(dd.target)
    of ddkAnyInteger:    return input.decode_anyint(dd)
    of ddkAnyUInteger:   return input.decode_anyuint(dd)
    of ddkIntRange:      return input.decode_intrange(dd)
    of ddkUIntRange:     return input.decode_uintrange(dd)
    of ddkAnyFloat:      return input.decode_anyfloat(dd)
    of ddkFloatRange:    return input.decode_floatrange(dd)
    of ddkAnyString:     return input.decode_anystring(dd)
    of ddkRegexesMatch:  return input.decode_regexesmatch(dd)
    of ddkRegexMatch:    return input.decode_regexmatch(dd)
    of ddkConst:         return input.decode_const(dd)
    of ddkEnum:          return input.decode_enum(dd)
    of ddkJson:          return input.decode_json(dd)
    of ddkList:          return input.decode_list(dd)
    of ddkStruct:        return input.decode_struct(dd)
    of ddkDict:          return input.decode_dict(dd)
    of ddkTags:          return input.decode_tags(dd)
    of ddkUnion:         return input.decode_union(dd)
  except DecodingError:
    let e = get_current_exception()
    raise_decoding_error(input, e.msg, dd)

proc recognize_and_decode*(input: string, dd: DatatypeDefinition):
                          tuple[name: string, decoded: JsonNode] =
  if dd.kind != ddkUnion:
    raise newException(TextformatsRuntimeError,
                       "Error while attempting to recognize and decode\n" &
                       &"The datatype '{dd.name}' is not a '{UnionDefKey}'")
  var
    errmsg: string
    i = 1
  for c in dd.choices:
    try:
      let decoded = input.decode(c)
      return (c.name, decoded)
    except DecodingError:
      let e = getCurrentException()
      errmsg &= &"[Alternative {i}] {c.name}\n\n{e.msg}\n\n"
    i += 1
  raise newException(DecodingError,
    &"Error while recognizing and decoding: '{input}'\n" &
    "The value is invalid according to all specified alternative formats.\n" &
    "The errors encountered for each of the alternatives are listed below.\n\n" &
     errmsg)

template open_input_file(filename: string): File =
  var file: File = nil
  try: file = open(filename)
  except IOError:
    let e = getCurrentException()
    raise newException(TextformatsRuntimeError,
                       "Error while reading input file '" & filename &
                       "'\n" & e.msg)
  file

iterator decode_lines*(filename: string, dd: DatatypeDefinition): JsonNode =
  ##
  ## Decode a file line by line.
  ## The dd defines a line and can have any type.
  ##
  let file = open_input_file(filename)
  for line in lines(file):
    yield line.decode(dd)

iterator decode_line_groups*(filename: string, dd: DatatypeDefinition,
                             n_lines_at_once: Natural): JsonNode =
  ##
  ## Decode a file by a pre-defined number of lines at once.
  ## The dd defines the group of lines.
  ##
  let file = open_input_file(filename)
  var
    linesgroup = newseq[string](n_lines_at_once)
    i = 0
  for line in lines(file):
    linesgroup[i] = line
    i += 1
    if i == n_lines_at_once:
      yield linesgroup.join("\n").decode(dd)
    i = 0
  if i > 0:
    raise newException(DecodingError,
                       "Final group of lines does not contain enough lines\n" &
                       &"Found n. of lines: {i}\n" &
                       &"Required n. of lines: {n_lines_at_once}")

iterator recognize_and_decode_lines*(filename: string, dd: DatatypeDefinition):
                          tuple[name: string, decoded: JsonNode] =
  let file = open_input_file(filename)
  for line in lines(file):
    yield line.recognize_and_decode(dd)

iterator decode_embedded*(filename: string, dd: DatatypeDefinition): JsonNode =
  let file = open_input_file(filename)
  var
    line_no = 0
    datasection = false
  for line in lines(file):
    if datasection:
      try:
        yield line.decode(dd)
        line_no += 1
      except DecodingError:
        var msg = &"Line content: '{line}'\n"
        msg &= &"Line number: {line_no}\n"
        raise newException(DecodingError, msg & getCurrentExceptionMsg())
    else:
      if line == "---":
        datasection = true

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
