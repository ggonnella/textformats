import strutils, strformat, json
import ../introspection
import ../types / [datatype_definition, def_syntax]

const union_describe* = "one of a list of possible datatypes"

proc union_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"\n{pfx}  there are {len(d.choices)} possible datatypes\n"
  if d.wrapped:
    result &= &"\n{pfx}- decoded value:\n"
    result &= &"{pfx}  the decoded data is a mapping which contains the " &
                "two keys 'type' and 'value'\n" &
              &"{pfx}  'type' indicates which " &
                "of the possible datatypes is used by the 'value' and is " &
                "one of the following: {d.branch_names}\n"
  result &= &"{pfx}  the possible datatypes are:\n"
  for i, c in d.choices:
    result &= &"\n{pfx}  - datatype '<{i}>' defined as\n" &
      c.verbose_desc(indent+4)

proc union_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}{UnionDefKey}:\n"
  for i, c in d.choices:
    result &= &"{pfx}- {c.repr_desc(indent+2)}"
  if d.wrapped:
    result &= &"{pfx}{WrappedKey}: true\n"
  result &= &"{pfx}{BranchNamesKey}: {%d.branch_names}\n"

proc union_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}- choices:\n"
  for i, c in d.choices:
    result &= &"{pfx}  - <{i}>:\n" & c.tabular_desc(indent+4)
  if d.wrapped:
    result &= &"{pfx}- wrapped; branch names: {d.branch_names}\n"
