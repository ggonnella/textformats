import strutils, strformat, options, tables, json
import ../introspection
import ../types / [datatype_definition, def_syntax]

const tags_describe* = "list of tagname/typecode/value tuples (value " &
            "semantics depends on tagname, datatype on typecode)"

proc tags_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"\n{pfx}  thereby the tag name matches the " &
              "regex '{d.tagname_regex_raw}'\n"
  result &= &"{pfx}  and the type code is one of the following:\n"
  for tagtype, valuedef in d.tagtypes:
    result &= &"\n{pfx}  - type code '{tagtype}', " &
               "for values with type:\n" &
               valuedef.verbose_desc(indent+4)
  if len(d.predefined_tags) > 0:
    result &= &"\n{pfx}- predefined tags\n" &
              &"{pfx}    the following tags, when " &
               "present, must have the specified type:\n" &
               &"{pfx}    {d.predefined_tags}\n"

proc tags_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}{TagsDefKey}:\n"
  for k, v in d.tagtypes:
    result &= &"\n{k}: "
    if v.kind == ddkRef:
      result &= &" {v.target_name}\n"
    else:
      result &= &"\n{v.repr_desc(indent+2)}"
  result &= &"{pfx}{TagnameKey}: {%d.tagname_regex_raw}\n"
  if len(d.predefined_tags) > 0:
    result &= &"{pfx}{PredefinedTagsKey}: {%(d.predefined_tags)}\n"

proc tags_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}- name regex: {d.tagname_regex_raw}\n"
  result &= &"{pfx}- members:\n"
  for tagtype, valuedef in d.tagtypes:
    result &= &"{pfx}  - {tagtype}:\n" & valuedef.tabular_desc(indent+4)
  result &= &"{pfx}- predefined tags: {d.predefined_tags}\n"
  result &= &"{pfx}- internal sep: '{d.tags_internal_sep}'\n"
