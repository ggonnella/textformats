import regex
import ../support/openrange
import ../types/datatype_definition
import ../regex_generator
import ../shared/seq_regex_generator

proc list_compute_regex*(dd: DatatypeDefinition) =
  assert dd.kind == ddkList
  let
    minlen = dd.lenrange.low
    maxlen = if dd.lenrange.has_high: dd.lenrange.high else: 0
  let member_re = dd.members_def.compute_and_get_regex()
  dd.regex.raw = member_re.raw.seq_regex(dd.sep.escape_re, minlen, maxlen)
  dd.regex.ensures_valid = member_re.ensures_valid
  dd.regex.constant_pfx = dd.pfx
  if minlen >= 1:
    dd.regex.constant_pfx &= dd.members_def.regex.constant_pfx

