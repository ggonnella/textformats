##
## Check and solve references in a Specification
##

# The code in this module does not depend on the specification
# format/syntax (differently from spec_parser).

import tables, strformat
import types / [datatype_definition, specification, textformats_error]
import support/directed_graph

template raise_brokenref(name, tname: untyped) =
  raise newException(BrokenRefError,
          "The definition of datatype '" & name & "' " &
          "refers to a datatype named '" & tname & "'.\n" &
          "However, no definition of '"  & tname & "' was found.")

proc resolve_references(dd: DatatypeDefinition, name: string,
                         spec: Specification) =
  if dd.has_unresolved_ref:
    if dd.kind == ddkRef:
      let tname = dd.target_name
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
    try:
      dependencies.add_edge(name, dd.target_name, true)
    except NodeNotFoundError:
      raise_brokenref(name, dd.target_name)
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
