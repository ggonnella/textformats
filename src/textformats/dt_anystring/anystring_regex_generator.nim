import ../types/datatype_definition

const AnyStringRE* = r".+"

proc anystring_compute_regex*(dd: DatatypeDefinition) =
  dd.regex.ensures_valid = true
  dd.regex.raw = AnyStringRE
