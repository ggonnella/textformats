import strutils, strformat, options, json
import ../support/openrange
import ../types / [datatype_definition, def_syntax]

const regexmatch_describe* = "string value matching a regular expression"

proc regexmatch_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"\n{pfx}  the regular expression is: '{d.regex.raw}'\n"
  if d.decoded[0].is_some:
    result &= &"{pfx}  matches are decoded as: {d.decoded[0].unsafe_get}\n"

proc regexmatch_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}{RegexMatchDefKey}:"
  if d.decoded[0].is_some:
    result &= &"{{{%d.regex.raw}: {d.decoded[0].unsafe_get}}}"
  else:
    result &= &"{%d.regex.raw}\n"

proc regexmatch_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}- regex: (see above)\n"
  result &= &"{pfx}- decoded: {d.decoded[0]}\n"
  result &= &"{pfx}- encoded: {d.encoded}\n"
