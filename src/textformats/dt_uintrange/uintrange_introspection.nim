import strutils, strformat, options
import ../support/openrange
import ../types / [datatype_definition, def_syntax]

const uintrange_describe* = "range of unsigned integer numbers"

proc uintrange_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"\n{pfx}  the range is {d.range_u}\n"
  result &= &"\n{pfx}  the number shall be in base {d.base}\n"

proc uintrange_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}{UintRangeDefKey}: {{"
  let
    l = d.range_u.lowstr
    h = d.range_u.highstr
  var any_added = false
  if l != "0":
    result &= &"{MinKey}: {l}"
    any_added = true
  if h != "Inf":
    if any_added:
      result &= ", "
    result &= &"{MaxKey}: {h}"
    any_added = true
  if d.base != 10:
    if any_added:
      result &= ", "
    result &= &"{BaseKey}: {d.base}"
  result &= "}\n"

proc uintrange_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}- range: {d.range_u}\n"
  result &= &"{pfx}- base: {d.base}\n"
