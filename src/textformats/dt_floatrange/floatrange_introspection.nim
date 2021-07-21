import strutils, strformat, options
import ../support/openrange
import ../types / [datatype_definition, def_syntax]

const floatrange_describe* = "range of floating point numbers"

proc floatrange_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"\n{pfx}  the range is: ({d.min_f},{d.max_f})\n"
  if d.max_incl:
    if d.min_incl:
      result &= &"{pfx}  (including the maximum and the minimum)\n"
    else:
      result &= &"{pfx}  (including the maximum but not the minimum)\n"
  else:
    if d.min_incl:
      result &= &"{pfx}  (including the minimum but not the maximum)\n"
    else:
      result &= &"{pfx}  (not including the minimum and the maximum)\n"

proc floatrange_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}{FloatRangeDefKey}: {{"
  let
    l = d.range_i.lowstr
    h = d.range_i.highstr
  var any_added = false
  if l != "-Inf":
    result &= &"{MinKey}: {l}"
    any_added = true
  if h != "Inf":
    if any_added:
      result &= ", "
    result &= &"{MaxKey}: {h}"
    any_added = true
  if not d.min_incl:
    if any_added:
      result &= ", "
    result &= &"{MinExcludedKey}: true"
    any_added = true
  if not d.max_incl:
    if any_added:
      result &= ", "
    result &= &"{MaxExcludedKey}: true"
  result &= "}\n"

proc floatrange_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}- range: ({d.min_incl},{d.min_f},{d.max_f},{d.max_incl})\n"
