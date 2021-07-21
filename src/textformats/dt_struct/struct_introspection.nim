import strutils, strformat, options
import ../introspection
import ../types / [datatype_definition, def_syntax]

const struct_describe* = "tuple of elements (of possibly different types)"

proc struct_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"\n{pfx}  the tuple contains {len(d.members)} elements\n"
  if d.n_required == len(d.members):
    result &= &"{pfx}  all elements of the tuple must be present\n"
  else:
    result &= &"{pfx}  of these, the first {d.n_required} " &
              "must be present, the remaining are optional\n"
  result &= &"\n{pfx}  the elements of the tuple are, in this order:\n"
  var i = 1
  for (k, v) in d.members:
    result &= &"\n{pfx}  - [{i}] element '{k}', defined as:\n" &
              v.verbose_desc(indent+4)
    i += 1

proc struct_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}{StructDefKey}:\n"
  for (k, v) in d.members:
    result &= &"{pfx}- {k}:"
    if v.kind == ddkRef:
      result &= &" {v.target_name}\n"
    else:
      result &= &"\n{v.repr_desc(indent+2)}"
  if d.n_required != len(d.members):
    result &= &"{NRequiredKey}: {d.n_required}\n"

proc struct_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}- members:\n"
  for (k, v) in d.members:
    result &= &"{pfx}  - {k}:\n" & v.tabular_desc(indent+4)
  result &= &"{pfx}- n_required: {d.n_required}\n"
