from re import escape_re
import ../types/datatype_definition
import ../types/match_element
import ../dt_anyfloat/anyfloat_regex_generator

proc const_compute_regex*(dd: DatatypeDefinition) =
  assert dd.kind == ddkConst
  dd.regex.ensures_valid = true
  case dd.constant_element.kind:
    of meString:
      dd.regex.raw = dd.constant_element.s_value.escape_re
    of meFloat:
      dd.regex.raw = AnyFloatRE
      dd.regex.ensures_valid = false
    of meInt:
      let i = dd.constant_element.i_value
      dd.regex.raw = if i > 0: "\\+?" & $i else: $i
