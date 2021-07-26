import ../types/datatype_definition
import ../support/openrange
import ../shared/intrange_regex_generator

const uintrange_rngregex_maxlen = 25

proc uintrange_compute_regex*(dd: DatatypeDefinition) =
  dd.regex.ensures_valid = false
  dd.regex.raw = block:
    case dd.base:
    of 10:
      let rngregex =
        if dd.range_u.has_high:
          uintrng_regex(dd.range_u.low, dd.range_u.high)
        elif dd.range_u.has_low:
          uint_gt_regex(dd.range_u.low)
        else:
          "(?:0|[1-9][0-9]*)"
      if len(rngregex) <= uintrange_rngregex_maxlen:
        dd.regex.ensures_valid = true
        rngregex
      else:
        "(?:0|[1-9][0-9]*)"
    of 2:  "(?:0[bB])?[_01]*[01][_01]*"
    of 8:  "(?:0[oO])?[_0-7]*[0-7][_0-7]*"
    of 16: "(?:0[xX]|#)?[_0-9A-Fa-f]*[0-9A-Fa-f][_0-9A-Fa-f]*"
    else:
      assert(false)
      ""
