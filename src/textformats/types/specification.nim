import tables, marshal, strformat, os, json, streams
import datatype_definition, textformats_error

export pairs

type
  Specification* = TableRef[string, DatatypeDefinition]

proc restore_references(dd: DatatypeDefinition, spec: Specification) =
  if dd.kind == ddkRef:
    dd.target = spec[dd.target_name]
    dd.target.restore_references(spec)
  else:
    for sub in dd.children:
      sub.restore_references(spec)

proc remove_references*(dd: DatatypeDefinition) =
  if dd.kind == ddkRef:
    dd.target = nil
  else:
    for sub in dd.children:
      sub.remove_references

proc save_specification*(table: Specification, filename: string) =
  try:
    for name, dd in table:
      dd.remove_references
    filename.writeFile($$table)
  except IOError:
    let e = get_current_exception()
    raise newException(TextformatsRuntimeError,
                       &"Error while saving specification file '{filename}'\n" &
                       e.msg)

proc load_specification*(filename: string): Specification =
  let errmsg_pfx = "Error loading preprocessed specification\n" &
                   &"  Filename: '{filename}'\n"
  try:
    let filecontent = filename.readFile()
    result = filecontent.to[:Specification]
    for name, dd in result:
      dd.restore_references(result)
    return
  except IOError:
    let errmsg = block:
      if not fileExists(filename): "File not found"
      else: get_current_exception().msg
    raise newException(TextformatsRuntimeError, errmsg_pfx & errmsg)
  except JsonParsingError:
    let errmsg = "  Parsing error: is it really a preprocessed specification?" &
              "\n  Please try repeating the preprocessing step."
    raise newException(TextformatsRuntimeError, errmsg_pfx & errmsg)

const BaseDatatypes* = [
  "integer", "unsigned_integer", "float", "string", "json"
]

template store_base_def(s: var Specification, n: string,
                        k: DatatypeDefinitionKind) =
  s[n] = DatatypeDefinition(kind: k, name: n)

proc create_base_datatypes(definitions: var Specification) =
  definitions.store_base_def("integer", ddkAnyInteger)
  definitions.store_base_def("unsigned_integer", ddkAnyUInteger)
  definitions.store_base_def("float", ddkAnyFloat)
  definitions.store_base_def("string", ddkAnyString)
  definitions.store_base_def("json", ddkJson)

proc newSpecification*(): Specification =
  result = newTable[string, DatatypeDefinition]()
  result.create_base_datatypes

proc is_preprocessed*(specfile: string): bool =
  let errmsg_pfx = "Error loading specification\n" &
                   &"  Filename: '{specfile}'\n"
  try:
    let stream = newFileStream(specfile, mode = fmRead)
    defer: stream.close()
    var magic_string: char
    discard stream.read_data(magic_string.addr, 1)
    return magic_string == '['
  except IOError:
    let errmsg = block:
      if not fileExists(specfile): "File not found"
      else: get_current_exception().msg
    raise newException(TextformatsRuntimeError, errmsg_pfx & errmsg)

proc datatype_names*(spec: Specification): seq[string] =
  for name, dd in spec:
    if name notin BaseDatatypes:
      result.add(name)

proc get_definition*(datatypes: Specification,
                     datatype = "default"): DatatypeDefinition =
  try:
    datatypes[datatype]
  except KeyError:
    raise newException(TextformatsRuntimeError,
              &"The datatype '{datatype}' is not defined in the specification.")
