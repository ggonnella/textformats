import ../types/datatype_definition
import ../support/openrange
import ../shared/intrange_regex_generator

proc intrange_compute_regex*(dd: DatatypeDefinition) =
  dd.regex.ensures_valid = true
  dd.regex.raw = intrng_regex(dd.range_i.low, dd.range_i.high)
