import regex
import ../types/datatype_definition
import ../regex_generator

proc regexesmatch_compute_regex*(dd: DatatypeDefinition) =
  assert dd.kind == ddkRegexesMatch
  assert dd.regexes_raw.len > 0
  dd.regexes_compiled = newseq[Regex]()
  dd.regex.ensures_valid = true
  dd.regex.raw = "("
  for i, e in dd.regexes_raw:
    let raw = dd.regexes_raw[i].wo_group_names
    dd.regexes_raw[i] = raw
    dd.regexes_compiled.add(raw.re)
    if i > 0: dd.regex.raw &= "|"
    dd.regex.raw &= raw
  dd.regex.raw &= ")"
