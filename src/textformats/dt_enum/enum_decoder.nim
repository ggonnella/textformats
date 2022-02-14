import json, strformat, strutils, options
import regex
import ../types / [datatype_definition, match_element,
                   textformats_error]
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
           &"Expected one of: {dd.elements.show_elements}\n")

proc prematched_decode_enum*(input: string, slice: Slice[int],
                              dd: DatatypeDefinition, m: RegexMatch,
                              childnum: int, groupspfx: string):
                                JsonNode =
  input[slice].decode_enum(dd)
