import strutils, strformat, options, json, tables
import regex
import ../types / [datatype_definition, textformats_error, regex_grppfx,
                   lines_reader]
import ../shared/formatting_decoder
import ../decoder

proc raise_invalid_element(emsg: string, membername: string) =
  raise newException(DecodingError,
          "Error: invalid encoded value for structure element\n" &
          &"Element name: {membername}\n{emsg.indent(2)}")

proc raise_invalid_min_n_elements(found: int, expected: int) =
  raise newException(DecodingError,
          "Error: invalid number of elements in structure\n" &
          &"Expected minimum number of elements: {expected}\n" &
          &"Found number of elements: {found}\n")

proc prematched_decode_struct*(input: string, slice: Slice[int],
            dd: DatatypeDefinition, match_obj: RegexMatch, childnum: int,
            groupspfx: string): JsonNode =
  var
    elements = newseq_of_cap[(string, JsonNode)](dd.members.len)
    i = 0
  for member in dd.members:
    let
      member_pfx = block:
        if groupspfx.len > 0: groupspfx & groupspfx_sep & $i
        else: $i
      matches = match_obj.group(member_pfx)
    if matches.len == 0:
      break
    if i notin dd.hidden:
      var subslice: Slice[int]
      if childnum == UnknownChildNum:
        # note: consider using binary search if lists are long
        for boundaries in matches:
          if (boundaries.a >= slice.a and boundaries.b <= slice.b):
            subslice = boundaries
            break
      else:
        subslice = matches[max(0, childnum)]
      try:
        let elem_decoded = input.prematched_decode(subslice, member.def,
                                            match_obj, childnum, member_pfx)
        elements.add((member.name, elem_decoded))
      except DecodingError:
        assert(false)
        #raise_invalid_element(getCurrentExceptionMsg(), member.name)
    i += 1
  if i < dd.n_required:
    raise_invalid_min_n_elements(i, dd.n_required)
  if dd.implicit.len > 0:
    elements &= dd.implicit
  result = newJObject()
  result.fields = elements.to_ordered_table

proc splitting_decode_struct(input: string, dd: DatatypeDefinition): JsonNode =
  var
    elements = newseq_of_cap[(string, JsonNode)](dd.members.len)
    i = 0
  let core = validate_and_remove_pfx_and_sfx(input, dd,
               emsg_pfx = "Error: wrong format for encoded structure\n")
  for elem in core.split(dd.sep, max_split=dd.members.len-1):
    let member = dd.members[i]
    try:
      let elem_decoded = elem.decode(member.def)
      if i notin dd.hidden:
        elements.add((member.name, elem_decoded))
    except DecodingError:
      raise_invalid_element(get_current_exception_msg(), member.name)
    i += 1
  if i < dd.n_required:
    raise_invalid_min_n_elements(i, dd.n_required)
  if dd.implicit.len > 0:
    elements &= dd.implicit
  result = newJObject()
  result.fields = elements.to_ordered_table

proc split_and_raise(input: string, dd: DatatypeDefinition) =
  # use the splitting method, which will also fails
  # but returns more informative errors than just "regex not matching"
  try:
    discard input.splitting_decode_struct(dd)
    do_assert(false)
  except DecodingError:
    raise newException(DecodingError,
                    "Error: encoded structure content not "&
                    "matching regular expression.\n" &
                    &"Regular expression: {dd.regex.raw}\n" &
                    "Reason for not matching: \n" &
                    get_current_exception_msg().indent(2))

proc elementwise_decode_struct(input: string, dd: DatatypeDefinition):
                               JsonNode =
  var
    match_obj: RegexMatch
    elements = newseq_of_cap[(string, JsonNode)](dd.members.len)
    i = 0
  if not input.match(dd.regex.compiled, match_obj):
    input.split_and_raise(dd)
  for member in dd.members:
    let
      member_pfx = $i
      matches = match_obj.group(member_pfx)
    if matches.len == 0:
      break
    assert(matches.len == 1)
    try:
      let elem_decoded = input.prematched_decode(matches[0], member.def,
                                  match_obj, NoChildNum, member_pfx)
      if i notin dd.hidden:
        elements.add((member.name, elem_decoded))
    except DecodingError:
      raise_invalid_element(get_current_exception_msg(), member.name)
    i += 1
  if i < dd.n_required:
    raise_invalid_min_n_elements(i, dd.n_required)
  if dd.implicit.len > 0:
    elements &= dd.implicit
  result = newJObject()
  result.fields = elements.to_ordered_table

proc decode_struct*(input: string, dd: DatatypeDefinition): JsonNode =
  assert dd.kind == ddkStruct
  if dd.sep.len > 0 and dd.sep_excl:
    return input.splitting_decode_struct(dd)
  else:
    return input.elementwise_decode_struct(dd)

proc decode_multiline_struct*(ls: var LinesReader, dd: DatatypeDefinition):
                             JsonNode =
  result = newJObject()
  var i = 0
  for member in dd.members:
    if ls.eof:
      if i < dd.n_required:
        raise_invalid_min_n_elements(i, dd.n_required)
      else:
        break
    try:
      result[member.name] = ls.decode_multiline(member.def)
      i += 1
    except DecodingError:
      if i < dd.n_required:
        raise_invalid_element(get_current_exception_msg(), member.name)
      else:
        break

proc decode_multiline_struct_lines*(ls: var LinesReader, dd: DatatypeDefinition,
                                    action: proc(j: JsonNode)) =
  var i = 0
  for member in dd.members:
    if ls.eof:
      if i < dd.n_required:
        raise_invalid_min_n_elements(i, dd.n_required)
      else:
        break
    try:
      ls.decode_multiline_lines(member.def, action)
      i += 1
    except DecodingError:
      continue
  if i < dd.n_required:
    raise_invalid_min_n_elements(i, dd.n_required)

