import ../types/datatype_definition

const AnyUIntegerRE = r"\d+"

proc anyuint_compute_regex*(dd: DatatypeDefinition) =
  dd.regex.ensures_valid = true
  dd.regex.raw = AnyUIntegerRE
