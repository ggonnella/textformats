import json, strutils, options, strformat
import regex
import ../support/openrange
import ../types / [datatype_definition, textformats_error, regex_grppfx,
                   lines_reader]
import ../shared/formatting_decoder
import ../decoder

proc raise_invalid_list_size(list_size: int, dd: DatatypeDefinition) =
  raise newException(DecodingError,
                    "Error: Invalid number of items in list.\n" &
                    &"Minimum valid n. of items: '{dd.lenrange.low}'\n" &
                    &"Maximum valid n. of items: '{dd.lenrange.highstr}'\n" &
                    &"Found n. of items: '{list_size}'\n")

proc raise_invalid_list_element(i: int, dd: DatatypeDefinition,
                                errmsg: string) =
  raise newException(DecodingError,
                     "Error: Invalid element in list.\n" &
                     &"Element number: {i}\n" &
                     &"Error while decoding element:\n" &
                     errmsg.indent(2))

proc raise_invalid_list_formatting(found: string, expected: string,
                                   label: string) =
  raise newException(DecodingError,
                      &"Error: Invalid {label} in list.\n" &
                      &"Expected {label}: '{expected}'\n" &
                      &"Found {label}: '{found}'\n")

proc raise_invalid_list_pfx(pfx: string, dd: DatatypeDefinition) =
  raise_invalid_list_formatting(pfx, dd.pfx, "prefix")

proc raise_invalid_list_sfx(sfx: string, dd: DatatypeDefinition) =
  raise_invalid_list_formatting(sfx, dd.sfx, "suffix")

proc raise_invalid_list_sep(sep: string, dd: DatatypeDefinition) =
  raise_invalid_list_formatting(sep, dd.sep, "separator")

template get_subgrppfx(groupspfx: string, itemN_pfx: string): string =
  if groupspfx.len > 0: groupspfx & groupspfx_sep & itemN_pfx
  else: itemN_pfx

proc prematched_decode_list*(input: string, slice: Slice[int],
                            dd: DatatypeDefinition, match_obj: RegexMatch,
                            childnum: int, groupspfx: string): JsonNode =
  result = newJArray()
  let
    pfx0 = get_subgrppfx(groupspfx, item0_pfx)
    pfx = get_subgrppfx(groupspfx, item_pfx)
  var has_i0 = false
  if pfx0 in match_obj.group_names:
    for subslice in match_obj.group(pfx0):
      if childnum == -1 or (subslice.a >= slice.b and subslice.b <= slice.b):
        try:
          let subchildnum = if childnum == -1: 0 else: -2
          result.add(input.prematched_decode(subslice, dd.members_def,
                                             match_obj, subchildnum, pfx0))
        except DecodingError:
          assert(false)
          #raise_invalid_list_element(0, dd, get_current_exception_msg())
        has_i0 = true
        break
  var i = 0
  for subslice in match_obj.group(pfx):
    if childnum == -1 or (subslice.a > slice.b and subslice.b <= slice.b):
      try:
        let subchildnum = if childnum == -1: i else: -2
        result.add(input.prematched_decode(subslice, dd.members_def,
                                           match_obj, subchildnum, pfx))
      except DecodingError:
        assert(false)
        #let coord = if has_i0: i+1 else: i
        #raise_invalid_list_element(coord, dd, get_current_exception_msg())
      i += 1
  if has_i0:
    i += 1
  if i notin dd.lenrange:
    assert(false)
    #raise_invalid_list_size(i, dd)

proc splitting_decode_list(input: string, dd: DatatypeDefinition): JsonNode =
  assert dd.kind == ddkList
  result = newJArray()
  var slice: Slice[int]
  slice.a = dd.pfx.len
  slice.b = input.len - 1 - dd.sfx.len
  if dd.pfx.len > 0:
    let pfx = input[0 ..< slice.a]
    if pfx != dd.pfx:
      raise_invalid_list_pfx(pfx, dd)
  if dd.sfx.len > 0:
    let sfx = input[slice.b + 1 ..< input.len]
    if sfx != dd.sfx:
      raise_invalid_list_sfx(sfx, dd)
  if input[slice].len == 0:
    if 0 in dd.lenrange: return
    else: raise_invalid_list_size(0, dd)
  var list_size = 0
  for elem in input[slice].split(dd.sep):
    var decoded: JsonNode
    try:
      decoded = elem.decode(dd.members_def)
    except DecodingError:
      raise_invalid_list_element(list_size, dd, get_current_exception_msg())
    result.add(decoded)
    list_size += 1
  if list_size notin dd.lenrange:
    raise_invalid_list_size(list_size, dd)

proc elementwise_decode_list(input: string, dd: DatatypeDefinition): JsonNode =
  assert dd.kind == ddkList
  result = newJArray()
  var
    list_size = 0
    rightmost = -1
  let core = validate_and_remove_pfx_and_sfx(input, dd,
               emsg_pfx = "Error: Invalid list format.\n")
  if core.len == 0:
    if 0 in dd.lenrange: return
    else: raise_invalid_list_size(0, dd)
  for m in core.find_all(dd.members_def.regex.compiled):
    let elem_bd = m.boundaries
    if list_size == 0:
      if elem_bd.a > 0:
        let pfx = dd.pfx & core[0 ..< elem_bd.a]
        raise_invalid_list_pfx(pfx, dd)
    else:
      if elem_bd.a > rightmost + 1:
        let sep = core[rightmost+1 ..< elem_bd.a]
        if sep != dd.sep:
          raise_invalid_list_sep(sep, dd)
    result.add(core.prematched_decode(elem_bd, dd.members_def, m, -1, ""))
    list_size += 1
    rightmost = elem_bd.b
  if rightmost < core.len-1:
    let sfx = core[rightmost+1 ..< core.len] & dd.sfx
    raise_invalid_list_sfx(sfx, dd)
  if list_size notin dd.lenrange:
    raise_invalid_list_size(list_size, dd)

proc decode_list*(input: string, dd: DatatypeDefinition): JsonNode =
  if dd.sep.len > 0 and dd.sep_excl:
    return input.splitting_decode_list(dd)
  else:
    return input.elementwise_decode_list(dd)

proc decode_multiline_list*(ls: var LinesReader, dd: DatatypeDefinition):
                           JsonNode =
  result = newJArray()
  var i = 0
  while i <= dd.lenrange.high:
    if ls.eof:
      if i < dd.lenrange.low: raise_invalid_list_size(i, dd)
      else: break
    try:
      result.add(ls.decode_multiline(dd.members_def))
      i += 1
    except DecodingError:
      if i == 0 or i < dd.lenrange.low:
        raise_invalid_list_element(i, dd, get_current_exception_msg())
      else: break

proc decode_multiline_list_lines*(ls: var LinesReader, dd: DatatypeDefinition,
                                  action: proc(j: JsonNode)) =
  var i = 0
  while i <= dd.lenrange.high:
    if ls.eof:
      if i < dd.lenrange.low: raise_invalid_list_size(i, dd)
      else: break
    try:
      ls.decode_multiline_lines(dd.members_def, action)
      i += 1
    except DecodingError:
      if i == 0 or i < dd.lenrange.low:
        raise_invalid_list_element(i, dd, get_current_exception_msg())
      else: break

