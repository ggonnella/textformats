import strutils, strformat
import ../types/datatype_definition

const anyfloat_describe* = "any floating point number"

proc anyfloat_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  return ""

proc anyfloat_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  return &"{pfx}float\n"

proc anyfloat_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  return ""
