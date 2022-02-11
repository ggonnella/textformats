import json, strformat, options
import regex
import ../types / [datatype_definition, textformats_error]
import ../shared/translation_decoder

template prematched_decode_regexmatch*(input: string, slice: Slice[int],
                 dd: DatatypeDefinition, m: RegexMatch, childnum: int,
                 groupspfx: string): JsonNode =
  input[slice].translated(dd)

proc decode_regexmatch*(input: string, dd: DatatypeDefinition): JsonNode =
  assert dd.kind == ddkRegexMatch
  when defined(trace_regex):
    debugEcho("trace_regex|decode|regexmatch|match(r)|" & dd.name)
  if input.match(dd.regex.compiled):
    return input.translated(dd)
  else:
    raise newException(DecodingError,
             &"Regular expression not matching: {dd.regex.raw}\n")
