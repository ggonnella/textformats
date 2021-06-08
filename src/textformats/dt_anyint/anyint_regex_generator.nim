import ../types/datatype_definition

const AnyIntegerRE = r"[+-]?\d+"

proc anyint_compute_regex*(dd: DatatypeDefinition) =
  dd.regex.ensures_valid = true
  dd.regex.raw = AnyIntegerRE
