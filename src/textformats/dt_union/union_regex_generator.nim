import strutils
import ../types/datatype_definition
import ../regex_generator

proc union_compute_regex*(dd: DatatypeDefinition) =
  assert dd.kind == ddkUnion
  var regexes = newseq[string](dd.choices.len)
  dd.regex.ensures_valid = true
  for i, e in dd.choices:
    var sub_re = e.compute_and_get_regex()
    dd.regex.ensures_valid = dd.regex.ensures_valid and sub_re.ensures_valid
    regexes[i] = sub_re.raw.pfx_group_names($i).to_named_group($i)
  if regexes.len == 1:
    dd.regex.raw = regexes[0]
  else:
    dd.regex.raw = "(" & regexes.join("|") & ")"

