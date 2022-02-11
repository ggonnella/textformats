import json, strutils, options
import regex
import ../types / [datatype_definition, textformats_error, regex_grppfx]
import ../shared/translation_decoder

proc decode_regexesmatch*(input: string, dd: DatatypeDefinition): JsonNode =
  assert dd.kind == ddkRegexesMatch
  when defined(trace_regex):
    debugEcho("trace_regex|decode|regexesmatch|" &
              "match(r) for r in regexes|" & dd.name)
  for i, r in dd.regexes_compiled:
    if input.match(r):
      return input.translated(dd, i)
  raise newException(DecodingError,
           "Regular expressions not matching: " &
           dd.regexes_raw.join(", ") & "\n")

proc prematched_decode_regexesmatch*(input: string, slice: Slice[int],
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
      for boundaries in match: # note: for large lists,
                               # a binary search would be better
        if boundaries == slice:
          return input[boundaries].translated(dd, i)
  assert(false)

