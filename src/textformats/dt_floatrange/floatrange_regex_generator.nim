import ../types/datatype_definition

const FloatRangeRE = r"[+-]?\d+\.\d+([eE][+-]?\d+)?"

proc floatrange_compute_regex*(dd: DatatypeDefinition) =
  dd.regex.ensures_valid = false
  dd.regex.raw = FloatRangeRE
