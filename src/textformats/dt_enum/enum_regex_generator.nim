from re import escape_re
import strutils, options
import ../types/datatype_definition
import ../types/match_element
import ../regex_generator
import ../dt_anyfloat/anyfloat_regex_generator

proc enum_compute_regex*(dd: DatatypeDefinition) =
  assert dd.kind == ddkEnum
  assert dd.elements.len > 0
  var
    float_added = false
    regexes = newseq[string](dd.elements.len)
  dd.regex.ensures_valid = true
  var has_translations = false
  for i, e in dd.elements:
    if dd.decoded[i].is_some:
      has_translations = true
    case e.kind:
      of meString:
        regexes[i] = e.s_value.escape_re
      of meFloat:
        if float_added:
          continue
        else:
          regexes[i] = AnyFloatRE
          dd.regex.ensures_valid = false
      of meInt:
        let i_str = if i > 0: "\\+?" & $i else: $i
        regexes[i] = i_str
  if has_translations:
    for i in 0..<dd.elements.len:
      regexes[i] = regexes[i].to_named_group($i)
  dd.regex.raw = "(" & regexes.join("|") & ")"
