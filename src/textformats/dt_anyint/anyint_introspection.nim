import strutils, strformat
import ../types/datatype_definition

const anyint_describe* = "any unsigned integer number"

proc anyint_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  return ""

proc anyint_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  return &"{pfx}integer\n"

proc anyint_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  return ""
