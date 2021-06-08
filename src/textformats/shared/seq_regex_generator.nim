import strformat
import ../support/openrange
import ../types/regex_grppfx
import ../regex_generator

proc size1_seq_regex(elem_re: string, allow_empty: bool): string {.inline.} =
  result = elem_re.pfx_group_names(item_pfx).to_named_group(item_pfx)
  if allow_empty:
    result &= "?"

proc sep_seq_regex(elem_re: string, esep: string, minlen: Natural,
                   maxlen: Natural): string {.inline.} =
  let
    maxs = if maxlen > 0: $(maxlen-1) else: ""
    mins = if minlen > 0: $(minlen-1) else: "0"
  result = elem_re.pfx_group_names(
                   item0_pfx).to_named_group(item0_pfx) &
                 &"({esep}" &
                 elem_re.pfx_group_names(
                   item_pfx).to_named_group(item_pfx) &
                 &"){{{mins},{maxs}}}"
  if minlen == 0:
    result = &"({result})?"

proc nosep_seq_regex(elem_re: string, minlen: Natural,
                     maxlen: Natural): string {.inline.} =
      result = elem_re.pfx_group_names(
                       item_pfx).to_named_group(item_pfx)
      if maxlen == 0:
        if minlen == 0:
          result &= "*"
        elif minlen == 1:
          result &= "+"
        else:
          result &= &"{{{minlen},}}"
      else:
        result &= &"{{{minlen},{maxlen}}}"

proc seq_regex*(elem_re: string, esep: string, minlen: Natural,
                     maxlen: Natural): string =
  do_assert maxlen == 0 or maxlen > 0 and maxlen >= minlen
  if maxlen == 1:
    size1_seq_regex(elem_re, minlen == 0)
  elif len(esep) > 0:
    sep_seq_regex(elem_re, esep, minlen, maxlen)
  else:
    nosep_seq_regex(elem_re, minlen, maxlen)
