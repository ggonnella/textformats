import strutils, strformat, options
import ../support/openrange
import ../types / [datatype_definition, def_syntax]

const intrange_describe* = "range of integer numbers"

proc intrange_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"\n{pfx}  the range is {d.range_i}\n"

proc intrange_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}{IntrangeDefKey}: {{"
  let
    l = d.range_i.lowstr
    h = d.range_i.highstr
  var l_added = false
  if l != "-Inf":
    result &= &"{MinKey}: {l}"
    l_added = true
  if h != "Inf":
    if l_added:
      result &= ", "
    result &= &"{MaxKey}: {h}"
  result &= "}\n"

proc intrange_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}- range: {d.range_i}\n"
