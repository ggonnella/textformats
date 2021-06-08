from re import escape_re
import tables
import strutils
import ../types/datatype_definition

proc tags_compute_regex*(dd: DatatypeDefinition)
import ../regex_generator

proc tags_compute_regex*(dd: DatatypeDefinition) =
  assert dd.kind == ddkTags
  var regexes = newseq_of_cap[string](dd.tagtypes.len)
  let isep = dd.tags_internal_sep.escape_re
  for typekey, value_def in dd.tagtypes:
    regexes.add(dd.tagname_regex_raw.wo_group_names & isep &
                typekey.escape_re & isep &
                value_def.compute_and_get_regex.raw)
  dd.regex.raw = "(" & regexes.join("|") & ")*"
  # does not ensures_valid since:
  # - the regex cannot test if keys are duplicated
  # - predefined tag names cannot be excluded in the generic
  #   regex for tagtypes which are wrong from them
  dd.regex.ensures_valid = false
