import ../types/datatype_definition
import ../support/openrange
import ../shared/intrange_regex_generator

proc uintrange_compute_regex*(dd: DatatypeDefinition) =
  dd.regex.ensures_valid = true
  dd.regex.raw = uintrng_regex(dd.range_u.low, dd.range_u.high)
