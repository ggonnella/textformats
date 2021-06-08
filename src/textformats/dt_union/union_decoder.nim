import json, strutils
import regex
import ../types / [datatype_definition, textformats_error, regex_grppfx]

proc prematched_decode_union*(input: string, slice: Slice[int],
                           dd: DatatypeDefinition, m: RegexMatch,
                           childnum: int, groupspfx: string):
                             JsonNode
import ../decoder

proc raise_all_invalid_error(errmsg: string) =
  raise newException(DecodingError,
          "Error: value is invalid for all specified formats\n" &
          "Error messages for each specified format:\n" & errmsg)

template appenderr(errmsg, i, choice: untyped) =
   errmsg &= "==== [" & $i & ": " & choice.name & "] ====\n" &
    get_current_exception_msg().indent(2) & "\n"

proc decode_union*(input: string, dd: DatatypeDefinition): JsonNode =
  assert dd.kind == ddkUnion
  var
    errmsg = ""
    i = 0
  for c in dd.choices:
    try: return input.decode(c)
    except DecodingError:
      errmsg.appenderr(i, c)
      i += 1
      continue
  raise_all_invalid_error(errmsg)

proc prematched_decode_union*(input: string, slice: Slice[int],
                           dd: DatatypeDefinition, m: RegexMatch,
                           childnum: int, groupspfx: string):
                             JsonNode =
  var errmsg = ""
  let pfx = if groupspfx.len > 0: groupspfx & groupspfx_sep else: ""
  for i in 0..<dd.choices.len:
    let
      choicepfx = pfx & $i
      choicematch = m.group(choicepfx)
    if choicematch.len > 0:
      if childnum == -1:
        assert(choicematch.len == 1)
        if dd.choices[i].regex.ensures_valid:
          return input.prematched_decode(choicematch[0], dd.choices[i], m, -1,
                                         choicepfx)
        else:
          for i2 in i..<dd.choices.len:
            try:
              return input.prematched_decode(choicematch[0], dd.choices[i2], m,
                                             -1, choicepfx)
            except DecodingError:
              errmsg.appenderr(i2, dd.choices[i2])
              continue
          raise_all_invalid_error(errmsg)
      else:
        for boundaries in choicematch: # note: for large lists,
                                 # a binary search would be better
          if boundaries == slice:
            if dd.choices[i].regex.ensures_valid:
              return input.prematched_decode(boundaries, dd.choices[i], m, -2,
                                             choicepfx)
            else:
              for i2 in i..<dd.choices.len:
                try:
                  return input.prematched_decode(boundaries, dd.choices[i2],
                                                 m, -2, choicepfx)
                except DecodingError:
                  errmsg.appenderr(i2, dd.choices[i2])
                  continue
              raise_all_invalid_error(errmsg)
  assert(false)

