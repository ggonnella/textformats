import strutils, strformat, options, json
import ../types / [datatype_definition, def_syntax]

const regexesmatch_describe* = "string value " &
                    "matching one of a list of regular expressions"

proc regexesmatch_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"\n{pfx}  the regular expressions are:\n"
  for i, element in d.regexes_raw:
    result &= &"{pfx}   [{i}] => '{element}'\n"
  for i, element in d.decoded:
    if element.is_some:
      result &= &"{pfx}    matches to {d.regexes_raw[i]}\n"
      result &= &"{pfx}      are decoded as: {element.unsafe_get}\n"

proc regexesmatch_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}{RegexesMatchDefKey}: ["
  for i, element in d.decoded:
    if i > 0:
      result &= ", "
    if element.is_some:
      result &= &"{%d.regexes_raw[i]}: {element.unsafe_get}"
    else:
      result &= &"{%d.regexes_raw[i]}"
  result &= "]\n"

proc regexesmatch_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}- regexes: {d.regexes_raw}\n"
  result &= &"{pfx}- decoded: {d.decoded}\n"
  result &= &"{pfx}- encoded: {d.encoded}\n"
