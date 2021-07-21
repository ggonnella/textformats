import strutils, strformat, options
import ../support/openrange
import ../introspection
import ../types / [datatype_definition, def_syntax]

const list_describe* = "list of elements of the same type"

proc list_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"\n{pfx}- validation:\n"
  result &= &"{pfx}  the list must contain between {d.lenrange.low} " &
            "and {d.lenrange.high} elements\n"
  result &= &"\n{pfx}- the type of list elements is:\n" &
            d.members_def.verbose_desc(indent+2)

proc list_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}{ListDefKey}:"
  if d.members_def.kind == ddkRef:
    result &= &" {d.members_def.target_name}\n"
  else:
    result &= &"\n{d.members_def.repr_desc(indent+2)}"

proc list_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}- lenrange: {d.lenrange}\n"
  result &= &"{pfx}- members_def:\n" & d.members_def.tabular_desc(indent+2)
