import json, strformat, strutils, options
import regex
import ../types / [datatype_definition, match_element,
                   regex_grppfx, textformats_error]
import ../shared/translation_decoder

proc show_elements(elements: seq[MatchElement]): string =
  var results = newseq_of_cap[string](elements.len)
  for e in elements:
    case e.kind:
    of meFloat:
      results.add(&"float: {e.f_value}")
    of meInt:
      results.add(&"int: {e.i_value}")
    of meString:
      results.add(&"string: '{e.s_value}'")
  return results.join(", ")

proc decode_enum*(input: string, dd: DatatypeDefinition): JsonNode =
  assert dd.kind == ddkEnum
  for i, me in dd.elements:
    case me.kind:
    of meFloat:
      var value: float
      try: value = parse_float(input) except ValueError: continue
      if value == me.f_value: return value.translated(dd, i)
    of meInt:
      var value: int
      try: value = parse_int(input) except ValueError: continue
      if value == me.i_value: return value.translated(dd, i)
    of meString:
      if input == me.s_value: return input.translated(dd, i)
  raise newException(DecodingError,
           "Error: Encoded value does not match any valid value.\n" &
           &"Valid values: {dd.elements.show_elements}")

proc prematched_decode_enum*(input: string, slice: Slice[int],
                              dd: DatatypeDefinition, m: RegexMatch,
                              childnum: int, groupspfx: string):
                                JsonNode =
  let pfx = if groupspfx.len > 0: groupspfx & groupspfx_sep else: ""
  for i in 0..<dd.elements.len:
    let match = m.group(pfx & $i)
    if childnum == -1:
      if match.len > 0:
        assert(match.len == 1)
        return input[match[0]].translated(dd, i)
    else:
      for boundaries in match:
        if boundaries == slice:
          return input[boundaries].translated(dd, i)
  assert(false)
