import strutils, strformat, options
import ../types / [datatype_definition, def_syntax]

proc as_string_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.as_string:
    result &= &"\n{pfx}- decoded value:\n" &
              &"{pfx}    the datatype definition is " &
                         "only used for validation\n" &
              &"{pfx}    and not for parsing, i.e. the decoded " &
                      "data is a string\n" &
              &"{pfx}    (identical to the encoded data)\n"

proc as_string_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.as_string:
    result &= &"{pfx}{AsStringKey}: true\n"

proc as_string_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.kind != ddkRef and d.kind != ddkAnyString and
     d.kind != ddkRegexMatch and d.kind != ddkRegexesMatch:
    result &= &"{pfx}- as_string: {d.as_string}\n"

