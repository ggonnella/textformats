import strutils, strformat, options
import ../types/datatype_definition

proc generated_regex_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.kind != ddkRef and d.kind != ddkRegexMatch:
    if len(d.regex.raw) > 0:
      result &= &"\n{pfx}- regular expression:\n"
      result &= &"{pfx}    regex which has been generated for the data type:\n"
      result &= &"{pfx}      '{d.regex.raw}'\n"
      result &= &"{pfx}    a match "
      if d.regex.ensures_valid:
        result &= "ensures "
      else:
        result &= "does not ensure "
      result &= &"validity of the encoded string\n"
      if not d.regex.ensures_valid:
        result &= &"{pfx}    (i.e. further operation are performed to " &
               "ensure validity)\n"

proc generated_regex_repr_desc*(d: DatatypeDefinition, indent: int): string =
  return ""

proc generated_regex_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.kind != ddkRef:
    result &= &"{pfx}- regex: "
    if d.regex_computed:
      result &= &"'{d.regex.raw}' (ensures_valid:"
      if d.regex.ensures_valid:
        result &= "y)"
      else:
        result &= "n)"
    else:
      result &= "-"
    result &= "\n"

