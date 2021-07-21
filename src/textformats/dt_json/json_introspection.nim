import strutils, strformat
import ../types/datatype_definition

const json_describe* = "JSON string"

proc json_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  return ""

proc json_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  return &"{pfx}json\n"

proc json_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  return ""
