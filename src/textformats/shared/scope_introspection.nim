import strutils, strformat
import ../types / [datatype_definition, def_syntax]

proc describe(scope: DatatypeDefinitionScope): string =
  case scope:
  of ddsUndef: "any part of a file (default)"
  of ddsLine: "a single line of a file"
  of ddsUnit: "a fixed number of lines of a file"
  of ddsSection: "a section of a file, with as many " &
                 "lines as fitting the definition"
  of ddsFile: "the entire file"

proc scope_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.scope != ddsUndef:
    result &= &"\n{pfx}Scope of the definition:\n"
    result &= &"{pfx}  {describe(d.scope)}\n"
    if d.scope == ddsUnit:
      result &= &"{pfx}  each unit consists of {d.unitsize} lines\n"

proc scope_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.scope != ddsUndef:
    result &= &"{pfx}{ScopeKey}: {d.scope}\n"
  if d.unitsize > 1:
    result &= &"{pfx}{UnitSizeKey}: {d.unitsize}\n"

proc scope_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  result &= &"{pfx}- scope: {d.scope}\n"
  if d.scope == ddsUnit:
    result &= &"{pfx}- unitsize: {d.unitsize}\n"

