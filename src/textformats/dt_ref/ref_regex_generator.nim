import ../types/datatype_definition
import ../regex_generator

proc ref_compute_regex*(dd: DatatypeDefinition) =
  do_assert(not dd.target.is_nil)
  let avoid_warning_tmp = dd.target.compute_and_get_regex()
  dd.regex = avoid_warning_tmp
