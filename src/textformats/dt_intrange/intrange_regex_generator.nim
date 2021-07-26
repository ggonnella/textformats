import ../types/datatype_definition
import ../support/openrange
import ../shared/intrange_regex_generator

const intrange_rngregex_maxlen = 25

proc intrange_compute_regex*(dd: DatatypeDefinition) =
  let rngregex =
    if dd.range_i.has_high:
      if dd.range_i.has_low:
        intrng_regex(dd.range_i.low, dd.range_i.high)
      else:
        int_lt_regex(dd.range_i.high)
    elif dd.range_i.has_low:
      int_gt_regex(dd.range_i.low)
    else:
       "(?:[+-](?:0|[1-9][0-9]*))"
  if len(rngregex) <= intrange_rngregex_maxlen:
    dd.regex.ensures_valid = true
    dd.regex.raw = rngregex
  else:
    dd.regex.ensures_valid = false
    dd.regex.raw = "(?:[+-](?:0|[1-9][0-9]*))"
