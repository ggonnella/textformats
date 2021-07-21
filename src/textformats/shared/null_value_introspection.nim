import strutils, strformat, options, json
import ../support/openrange
import ../types / [datatype_definition, def_syntax]

proc null_value_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.kind != ddkRef:
    if d.null_value.is_some:
      result &= &"\n{pfx}- default decoded value:\n"
      result &= &"{pfx}  the encoded string may be empty\n"
      result &= &"{pfx}  which is decoded as: " &
                $((d.null_value).unsafe_get) & "\n"

proc null_value_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.null_value.is_some:
    result &= &"{pfx}{NullValueKey}: {d.null_value.unsafe_get}\n"

proc null_value_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.kind != ddkRef:
    if d.null_value.is_some:
      result &= &"{pfx}- null_value: '"
      result &= $((d.null_value).unsafe_get)
      result &= "'\n"
    else:
      result &= &"{pfx}- null_value: -\n"

