import ../types/datatype_definition
import ../support/openrange
import ../shared/intrange_regex_generator

proc uintrange_compute_regex*(dd: DatatypeDefinition) =
  if dd.base == 10:
    dd.regex.ensures_valid = true
    dd.regex.raw = uintrng_regex(dd.range_u.low, dd.range_u.high)
  else:
    dd.regex.ensures_valid = false
    if dd.base == 2:
      dd.regex.raw = "(0[bB])?[_01]*[01][_01]*"
    elif dd.base == 8:
      dd.regex.raw = "(0[oO])?[_0-7]*[0-7][_0-7]*"
    elif dd.base == 16:
      dd.regex.raw = "(0[xX]|#)?[_0-9A-Fa-f]*[0-9A-Fa-f][_0-9A-Fa-f]*"
    else:
      assert(false)
