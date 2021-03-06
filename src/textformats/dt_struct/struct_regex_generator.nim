import regex
import strutils
import ../types/datatype_definition

proc struct_compute_regex*(dd: DatatypeDefinition)
import ../regex_generator

proc struct_compute_regex*(dd: DatatypeDefinition) =
  assert dd.kind == ddkStruct
  dd.regex.ensures_valid = true
  dd.regex.raw = ""
  dd.regex.constant_pfx = dd.pfx
  for i, (mname, mdef) in dd.members:
    var sub_re = mdef.compute_and_get_regex()
    dd.regex.ensures_valid = dd.regex.ensures_valid and sub_re.ensures_valid
    if i >= dd.n_required:
      dd.regex.raw &= "(?:"
    if i > 0:
      dd.regex.raw &= dd.sep.escape_re
    else:
      dd.regex.constant_pfx &= mdef.regex.constant_pfx
    dd.regex.raw &= sub_re.raw.pfx_group_names($i).to_named_group($i)
  dd.regex.raw &= ")?".repeat(dd.members.len - dd.n_required)

