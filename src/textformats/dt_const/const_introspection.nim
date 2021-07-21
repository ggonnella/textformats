import strutils, strformat, options, json
import ../types / [datatype_definition, def_syntax, match_element]

const const_describe* = "constant value"

proc const_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"\n{pfx}  the constant value is {d.constant_element}\n"
  if d.decoded[0].is_some:
    result &= &"{pfx}  which is decoded as: {d.decoded[0].unsafe_get}\n"

proc const_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}{ConstDefKey}: "
  if d.decoded[0].is_some:
    result &= &"{{{d.constant_element.to_json}: {d.decoded[0].unsafe_get}}}\n"
  else:
    result &= &"{d.constant_element.to_json}\n"

proc const_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}- constant_element: {d.constant_element}\n"
  result &= &"{pfx}- decoded: {d.decoded[0]}\n"
