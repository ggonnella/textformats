import ../types/datatype_definition

const AnyIntegerRE = r"(0|[+-]?[1-9][0-9]*)"

proc anyint_compute_regex*(dd: DatatypeDefinition) =
  dd.regex.ensures_valid = true
  dd.regex.raw = AnyIntegerRE
