import strutils
import ../types/datatype_definition
import ../regex_generator

proc union_compute_regex*(dd: DatatypeDefinition) =
  assert dd.kind == ddkUnion
  var regexes = newseq[string](dd.choices.len)
  dd.branch_pfx = newseq[string](dd.choices.len)
  dd.branch_pfx_ensure = true
  dd.regex.ensures_valid = true
  for i, e in dd.choices:
    var sub_re = e.compute_and_get_regex()
    dd.regex.ensures_valid = dd.regex.ensures_valid and sub_re.ensures_valid
    regexes[i] = sub_re.raw.pfx_group_names($i).to_named_group($i)
    if len(e.regex.constant_pfx) == 0:
      dd.branch_pfx_ensure = false
    elif dd.branch_pfx_ensure:
      # O(n_branches^2) but n_branches is small:
      if e.regex.constant_pfx in dd.branch_pfx:
        dd.branch_pfx_ensure = false
    dd.branch_pfx[i] = e.regex.constant_pfx
  if regexes.len == 1:
    dd.regex.raw = regexes[0]
  else:
    dd.regex.raw = "(" & regexes.join("|") & ")"

