import regex
import strutils
import ../types/datatype_definition
import ../types/match_element
import ../dt_anyfloat/anyfloat_regex_generator

proc enum_compute_regex*(dd: DatatypeDefinition) =
  assert dd.kind == ddkEnum
  assert dd.elements.len > 0
  var
    float_added = false
    regexes = newseq[string](dd.elements.len)
  dd.regex.ensures_valid = true
  var
    charclass = true
  for i, e in dd.elements:
    case e.kind:
      of meString:
        if len(e.s_value) > 1:
          charclass = false
        let rgx = e.s_value.escape_re
        regexes[i] = rgx
      of meFloat:
        if float_added:
          continue
        else:
          regexes[i] = AnyFloatRE
          dd.regex.ensures_valid = false
          charclass = false
      of meInt:
        let i_str = if i > 0: "\\+?" & $i else: $i
        regexes[i] = i_str
        charclass = false
  if charclass:
    dd.regex.raw = "[" & regexes.join("") & "]"
  else:
    dd.regex.raw = "(" & regexes.join("|") & ")"
