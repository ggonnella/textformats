##
## Check and solve references in a Specification
##

# The code in this module does not depend on the specification
# format/syntax (differently from spec_parser).

import tables, strformat, strutils
import types / [datatype_definition, specification, textformats_error,
                def_syntax]
import support/directed_graph

template raise_brokenref(name, tname: untyped) =
  raise newException(BrokenRefError,
          "The definition of datatype '" & name & "' " &
          "refers to a datatype named '" & tname & "'.\n" &
          "However, no definition of '"  & tname & "' was found.")

proc qualified_target_name(dd: DatatypeDefinition, name: string): string =
  if dd.target_name notin BaseDatatypes:
    let name_parts = name.rsplit(NamespaceSeparator, 1)
    if len(name_parts) == 2:
      let
        name_first = name.split(NamespaceSeparator, 1)[0]
        target_name_parts = dd.target_name.split(NamespaceSeparator, 1)
        target_name_first = target_name_parts[0]
      if (len(target_name_parts) == 1) or (name_first != target_name_first):
        dd.target_name = name_parts[0] & NamespaceSeparator & dd.target_name
  return dd.target_name

proc resolve_references(dd: DatatypeDefinition, name: string,
                        spec: Specification) =
  if dd.has_unresolved_ref:
    if dd.kind == ddkRef:
      let tname = dd.qualified_target_name(name)
      if tname notin spec:
        raise_brokenref(name, tname)
      let target = spec[tname]
      if target.has_unresolved_ref:
        target.resolve_references(tname, spec)
      dd.target = target
    else:
      for sub in dd.children:
        sub.resolve_references(name, spec)
  dd.has_unresolved_ref = false

proc resolve_references*(spec: Specification) =
  for name, definition in spec:
    definition.resolve_references(name, spec)

proc construct_dependency_subgraph(dd: DatatypeDefinition, name: string,
                                   dependencies: Graph) =
  if dd.kind == ddkRef:
    let tname = dd.qualified_target_name(name)
    try:
      dependencies.add_edge(name, tname, true)
    except NodeNotFoundError:
      raise_brokenref(name, tname)
  else:
    for sub in dd.children:
      sub.construct_dependency_subgraph(name, dependencies)

proc validate_dependencies*(spec: Specification) =
  var dependencies = newGraph()
  for name, dd in spec:
    dd.construct_dependency_subgraph(name, dependencies)
  try:
    dependencies.validate_dag
  except CycleFoundError:
    raise newException(CircularDefError,
       "\nCircular definition found.\n" &
       "The definition of a datatype " &
       "refers to datatypes which are dependent on " &
       "its own definition.\n")
