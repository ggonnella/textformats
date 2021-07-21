import strutils, strformat
import ../types/datatype_definition

const anystring_describe* = "any string value"

proc anystring_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  return ""

proc anystring_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  return &"{pfx}string\n"

proc anystring_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  return ""
