import strutils, strformat, options, tables
import ../types / [datatype_definition, def_syntax, match_element]

const enum_describe* = "one of a set of accepted values"

proc enum_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"\n{pfx}  the accepted values are:\n"
  for i, element in d.elements:
    result &= &"{pfx}    {d.elements[i]}"
    if d.decoded[i].is_some:
      result &= &" decoded as: {d.decoded[i].unsafe_get}"
    result &= "\n"

proc enum_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}{EnumDefKey}: ["
  for i, element in d.elements:
    if i > 0:
      result &= ", "
    result &= d.elements[i].to_json
    if d.decoded[i].is_some:
      result &= &": {d.decoded[i].unsafe_get}"
  result &= "]\n"

proc enum_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}- elements: {d.elements}\n"
  result &= &"{pfx}- decoded: {d.decoded}\n"
  result &= &"{pfx}- encoded: {d.encoded}\n"
