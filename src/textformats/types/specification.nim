import tables, strformat, os, json, streams
import datatype_definition, textformats_error
import msgpack4nim

export pairs

type
  Specification* = TableRef[string, DatatypeDefinition]

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

proc restore_references(dd: DatatypeDefinition, spec: Specification) =
  if dd.has_unresolved_ref:
    if dd.kind == ddkRef:
      dd.target = spec[dd.target_name]
    else:
      for sub in dd.children:
        sub.restore_references(spec)
  dd.has_unresolved_ref = false

proc remove_references*(dd: DatatypeDefinition) =
  if dd.kind == ddkRef:
    dd.target = nil
  else:
    for sub in dd.children:
      sub.remove_references
  dd.has_unresolved_ref = true

const
  TFS_MAGIC_STRING* = "TFS1.0--"

proc save_specification*(table: Specification, filename: string) =
  try:
    var s = newFileStream(filename, fmWrite)
    s.write(TFS_MAGIC_STRING)
    s.pack(table.len)
    for k, v in table:
      s.pack(k)
      s.pack(v)
    s.close()
  except IOError:
    let e = get_current_exception()
    raise newException(TextFormatsRuntimeError,
                       &"Error while saving specification file '{filename}'\n" &
                       e.msg)

proc load_specification*(filename: string): Specification =
  if filename == "":
    raise newException(TextFormatsRuntimeError,
                       "reading compiled specifications " &
                       "from standard input not supported")
  let errmsg_pfx = "Error loading compiled specification\n" &
                   &"  Filename: '{filename}'\n"
  var s: FileStream
  try:
    s = newFileStream(filename, fmRead)
  except IOError:
    let errmsg = block:
      if not fileExists(filename): "File not found"
      else: get_current_exception().msg
    raise newException(TextFormatsRuntimeError, errmsg_pfx & errmsg)
  var magic_string = "        "
  discard s.read_data_str(magic_string, 0..7)
  if magic_string != TFS_MAGIC_STRING:
    raise newException(TextFormatsRuntimeError,
                       errmsg_pfx &
                       "Magic string not found, file is not TFS")
  result = newSpecification()
  try:
    var l: int
    s.unpack(l)
    for i in 0 ..< l:
      var
        k: string
        v: DatatypeDefinition
      s.unpack(k)
      s.unpack(v)
      result[k] = v
    s.close()
  except:
    let errmsg = "  Parsing error: is it really a compiled specification?" &
                "\n  Please try repeating the compilation."
    raise newException(TextFormatsRuntimeError, errmsg_pfx & errmsg)
  for name, dd in result:
    dd.restore_references(result)

const BaseDatatypes* = [
  "integer", "unsigned_integer", "float", "string", "json"
]

proc is_compiled*(specfile: string): bool =
  if specfile == "":
    return false
  let errmsg_pfx = "Error loading specification\n" &
                   &"  Filename: '{specfile}'\n"
  try:
    let stream = newFileStream(specfile, mode = fmRead)
    defer: stream.close()
    var magic_string = "        "
    discard stream.read_data_str(magic_string, 0..7)
    return magic_string == "TFS1.0--"
  except IOError:
    let errmsg = block:
      if not fileExists(specfile): "File not found"
      else: get_current_exception().msg
    raise newException(TextFormatsRuntimeError, errmsg_pfx & errmsg)

proc datatype_names*(spec: Specification): seq[string] =
  for name, dd in spec:
    if name notin BaseDatatypes:
      result.add(name)

proc get_definition*(datatypes: Specification,
                     datatype = "default"): DatatypeDefinition =
  try:
    datatypes[datatype]
  except KeyError:
    raise newException(TextFormatsRuntimeError,
              &"The datatype '{datatype}' is not defined in the specification.")
