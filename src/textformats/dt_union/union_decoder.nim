import json, strutils, strformat
import regex
import ../types / [datatype_definition, textformats_error, regex_grppfx]

proc prematched_decode_union*(input: string, slice: Slice[int],
                           dd: DatatypeDefinition, m: RegexMatch,
                           childnum: int, groupspfx: string):
                             JsonNode
import ../decoder

proc raise_all_invalid_error(errmsg: string) =
  raise newException(DecodingError,
          "Value invalid for all possible formats. Error messages:\n" & errmsg)

template appenderr(errmsg, i, choice: untyped) =
   errmsg &= "==== [" & $i & ": " & choice.name & "] ====\n" &
    get_current_exception_msg().indent(2) & "\n"

template wrapped(value: JsonNode, dd: DatatypeDefinition): JsonNode =
  if dd.wrapped: %{dd.branch_names[i]: value}
  else: value

proc decode_union*(input: string, dd: DatatypeDefinition): JsonNode =
  assert dd.kind == ddkUnion
  var errmsg = ""
  for i, pfx in dd.branch_pfx:
    if len(pfx) == 0 or input[0 ..< len(pfx)] == pfx:
      try:
        return input.decode(dd.choices[i]).wrapped(dd)
      except DecodingError:
        if dd.branch_pfx_ensure:
          let e = getCurrentException()
          e.msg = &"Format identified by prefix '{pfx}' " &
                  "but value is invalid:\n" & e.msg.indent(2)
          raise
        else:
          errmsg.appenderr(i, dd.choices[i])
          continue
  raise_all_invalid_error(errmsg)

proc prematched_decode_union*(input: string, slice: Slice[int],
                           dd: DatatypeDefinition, m: RegexMatch,
                           childnum: int, groupspfx: string):
                             JsonNode =
  var errmsg = ""
  let gpfx = if groupspfx.len > 0: groupspfx & groupspfx_sep else: ""
  for i in 0..<dd.choices.len:
    let
      choicegpfx = gpfx & $i
      choicematch = m.group(choicegpfx)
    if choicematch.len > 0:
      #
      # there are matches for this branch, so it must be either
      # this branch or one of the following (in case the match does
      # not ensure validity)
      #
      for boundaries in choicematch: # could be optimized
                                     # with bsearch if list is long
        let subchildnum = if childnum == -1: -1 else: -2
        if childnum == -1 or boundaries == slice:
          # input[boundaries] is the string to decode
          # with any dd.choices[i..<dd.choice.len] with compatible prefix
          for i2 in i..<dd.choices.len:
            let pfx = dd.branch_pfx[i2]
            if len(pfx) == 0 or input[boundaries][0 ..< len(pfx)] == pfx:
              try:
                return input.prematched_decode(boundaries, dd.choices[i2], m,
                                               subchildnum,
                                               choicegpfx).wrapped(dd)
              except DecodingError:
                if dd.branch_pfx_ensure:
                  let e = getCurrentException()
                  e.msg = &"Format identified by prefix '{pfx}' " &
                          "but value is invalid:\n" & e.msg.indent(2)
                  raise
                else:
                  errmsg.appenderr(i2, dd.choices[i2])
                  continue
          raise_all_invalid_error(errmsg)
  assert(false)

