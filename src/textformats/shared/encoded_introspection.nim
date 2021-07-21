import strutils, strformat, options, tables
import ../support/openrange
import ../types / [datatype_definition, def_syntax]

proc encoded_verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.encoded.is_some:
    let etab = d.encoded.unsafe_get
    result &= &"{pfx}- encoding rules:\n"
    for k, v in etab:
      result &= &"{pfx}    {k} is encoded as {v}\n"

proc encoded_repr_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.encoded.is_some:
    let etab = d.encoded.unsafe_get
    result &= &"{pfx}{EncodedKey}: {{\n"
    var any_added = false
    for k, v in etab:
      if any_added:
        result &= ", "
      result &= &"{v}: {k}"
      any_added = true
    result &= "}\n"

proc encoded_tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.encoded.is_some:
    let etab = d.encoded.unsafe_get
    result &= &"{pfx} - encoded: {{\n"
    var any_added = false
    for k, v in etab:
      if any_added:
        result &= ", "
      result &= &"{v}: {k}"
      any_added = true
    result &= "}\n"

