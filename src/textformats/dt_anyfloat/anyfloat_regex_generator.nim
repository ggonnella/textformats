import ../types/datatype_definition

const AnyFloatRE* = r"[+-]?(\d+\.\d+([eE][+-]?\d+)?|[iI][nN][fF]|[nN][aA][nN])"

proc anyfloat_compute_regex*(dd: DatatypeDefinition) =
  dd.regex.ensures_valid = true
  dd.regex.raw = AnyFloatRE
