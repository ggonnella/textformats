import ../types/datatype_definition

const AnyUIntegerRE = r"(?:0|[1-9][0-9]*)"

proc anyuint_compute_regex*(dd: DatatypeDefinition) =
  dd.regex.ensures_valid = true
  dd.regex.raw = AnyUIntegerRE
