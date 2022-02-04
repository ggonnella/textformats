import strutils, strformat
import ../types / [datatype_definition, def_syntax]

proc implicit_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if len(d.implicit) > 0:
    result &= &"{pfx}- implicit values:\n" &
              &"{pfx}  the following key/value pairs are " &
               "additionally included in the decoded value:\n"
    for (k, v) in d.implicit:
      result &= &"{pfx}    {k} => {v}\n"

proc implicit_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if len(d.implicit) > 0:
    result &= &"{pfx}{ImplicitKey}: {{"
    var any_added = false
    for (k, v) in d.implicit:
      if any_added:
        result &= ", "
      result &= &"{k}: {v}"
      any_added = true
    result &= "}\n"

proc implicit_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.kind == ddkStruct or d.kind == ddkDict or d.kind == ddkTags:
    result &= &"{pfx}- implicit:"
    if len(d.implicit) > 0:
      result &= "\n"
      for (k, v) in d.implicit:
        result &= &"{pfx}  - {k}:{v}\n"
    else:
      result &= " []\n"

