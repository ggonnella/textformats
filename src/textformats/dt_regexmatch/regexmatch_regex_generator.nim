import ../types/datatype_definition
import ../regex_generator

proc regexmatch_compute_regex*(dd: DatatypeDefinition) =
  assert dd.kind == ddkRegexMatch
  dd.regex.raw = dd.regex.raw.wo_group_names
  dd.regex.ensures_valid = true
