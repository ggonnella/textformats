import strutils, strformat
import ../types/datatype_definition

const anyuint_describe* = "any unsigned integer number"

proc anyuint_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  return ""

proc anyuint_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  return &"{pfx}unsigned_integer\n"

proc anyuint_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  return ""
