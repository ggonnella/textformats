import strutils, strformat, options
import ../introspection
import ../types / [datatype_definition]

const ref_describe* = "reference to another definition"

proc ref_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.has_unresolved_ref:
    result &= &"\n{pfx}  the target of the reference is: <{d.target_name}>\n"
  else:
    assert not d.target.is_nil
    result &= &"\n{pfx}  the target of the reference is "
    if d.target_name.len > 0:
      result &= &"'{d.target_name}' "
    else:
      result &= "(anonymous) "
    result &= &"defined as:\n"
    result &= d.target.verbose_desc(indent+2)

proc ref_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  return &"{pfx}{d.target_name}\n"

proc ref_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.has_unresolved_ref:
    result &= &"{pfx}- target: <{d.target_name}>\n"
  else:
    assert not d.target.is_nil
    result &= &"{pfx}- target:"
    if d.target_name.len > 0:
      result &= &" ('{d.target_name}')"
    else:
      result &= " (anonymous)"
    result &= "\n" & d.target.tabular_desc(indent+2)
