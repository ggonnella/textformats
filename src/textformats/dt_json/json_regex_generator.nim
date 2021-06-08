import ../types/datatype_definition

const JsonRE* = r"[ !-~]+"

proc json_compute_regex*(dd: DatatypeDefinition) =
  dd.regex.ensures_valid = false
  dd.regex.raw = JsonRE
