import strutils, strformat, tables
import ../introspection
import ../types / [datatype_definition, def_syntax]

const dict_describe* = "list of key/value pairs (key determines semantics " &
            "and datatype of value)"

proc dict_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"\n{pfx}  thereby the key is one of the following " &
            &"{len(d.dict_members)} keys:\n"
  var i = 1
  for k, v in d.dict_members:
    result &= &"\n{pfx}  - [{i}] key '{k}', for which the value has " &
             "the following type:\n" & v.verbose_desc(indent+4)
    i += 1
  if len(d.required_keys) > 0 or len(d.single_keys) > 0:
    result &= &"\n{pfx}- validation:\n"
    if len(d.required_keys) > 0:
      result &= &"{pfx}    the following keys must always be present: " &
                d.required_keys.join(", ") & "\n"
    if len(d.single_keys) > 0:
      result &= &"{pfx}    the following keys can only be present once: " &
                d.single_keys.join(", ") & "\n"

proc dict_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}{DictDefKey}:\n"
  for k, v in d.dict_members:
    result &= &"\n{k}: "
    if v.kind == ddkRef:
      result &= &" {v.target_name}\n"
    else:
      result &= &"\n{v.repr_desc(indent+2)}"
  if len(d.required_keys) > 0:
    result &= &"{pfx}{DictRequiredKey}: [" &
              d.required_keys.join(", ") & "]\n"
  if len(d.single_keys) > 0:
    result &= &"{pfx}{SingleKey}: [" &
              d.single_keys.join(", ") & "]\n"

proc dict_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}- members:\n"
  for k, v in d.dict_members:
    result &= &"{pfx}  - {k}:\n" & v.tabular_desc(indent+4)
  result &= &"{pfx}- required: {d.required_keys}\n"
  result &= &"{pfx}- single: {d.single_keys}\n"
  result &= &"{pfx}- internal sep: '{d.dict_internal_sep}'\n"
