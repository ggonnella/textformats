import regex
import tables
import ../types/datatype_definition
import ../shared/seq_regex_generator

proc dict_compute_regex*(dd: DatatypeDefinition)
import ../regex_generator

proc anykey_regex(dd: DatatypeDefinition): string =
  var i = 0
  result = "("
  for key in dd.dict_members.keys:
    if i > 0: result &= "|"
    result &= key.escape_re
    i += 1
  result &= ")"

#
# just uses .* for the values
#
# one could use the value_defs associated to each key
# however, this can lead to a very long regex, which must
# be repeated twice (for item0 and item); furthermore, it
# still does not ensures_valid, since it cannot check if
# the keys are duplicated and if the non-optional keys
# are all present
#

proc anyelem_regex(dd: DatatypeDefinition): string =
  dd.anykey_regex & dd.dict_internal_sep.escape_re & ".*"

proc dict_compute_regex*(dd: DatatypeDefinition) =
  assert dd.kind == ddkDict
  dd.regex.ensures_valid = false
  for key, value in dd.dict_members:
    discard value.compute_and_get_regex
  let
    anyelem_re = dd.anyelem_regex
    minlen = len(dd.required_keys)
  dd.regex.raw = anyelem_re.seq_regex(dd.sep.escape_re, minlen, 0)
