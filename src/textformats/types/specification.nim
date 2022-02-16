import tables, strformat, os, json, streams, strutils
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
    let s = block:
      if filename == "" : newFileStream(stdout)
      else: newFileStream(filename, fmWrite)
    defer: s.close()
    s.write(TFS_MAGIC_STRING)
    s.pack(table.len)
    for k, v in table:
      s.pack(k)
      s.pack(v)
  except IOError:
    let e = get_current_exception()
    raise newException(TextFormatsRuntimeError,
                       &"Error while saving specification file '{filename}'\n" &
                       e.msg)

proc load_specification_stream(s: Stream, filedesc: string): Specification =
  let errmsg_pfx = "Error loading pre-compiled specification\n" &
                   "  " & filedesc & "\n"
  var magic_string = "        "
  discard s.read_data_str(magic_string, 0..7)
  if magic_string != TFS_MAGIC_STRING:
    raise newException(TextFormatsRuntimeError,
                       errmsg_pfx &
                       "Magic string not found, invalid TFS file\n" &
                       &"Found: '{magic_string}'\n" &
                       &"Expected: '{TFS_MAGIC_STRING}'\n")
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
    let errmsg = "  Parsing error: invalid TFS file\n" &
                 "  Please try repeating the compilation."
    raise newException(TextFormatsRuntimeError, errmsg_pfx & errmsg)
  for name, dd in result:
    dd.restore_references(result)

proc load_specification*(filename: string): Specification =
  var
    stream: Stream
    filedesc: string
  if filename == "":
    stream = newStringStream(stdin.read_all())
    filedesc = "Reading from standard input"
  elif not fileExists(filename):
    let errmsg = "Error loading pre-compiled specification:\n" &
             &"  File not found: '{filename}'\n"
    raise newException(TextFormatsRuntimeError, errmsg)
  else:
    filedesc = &"Filename: '{filename}'"
    try:
      stream = newFileStream(filename, fmRead)
    except IOError:
      let errmsg = "Error loading pre-compiled specification:\n" &
               "  " & filedesc & "\n" &
               getCurrentExceptionMsg().indent(2)
      raise newException(TextFormatsRuntimeError, errmsg)
  defer: stream.close()
  return load_specification_stream(stream, filedesc)

proc load_specification_buffer*(buffer: string,
        filedesc = "Reading from standard input"): Specification =
  let stream = newStringStream(buffer)
  defer: stream.close()
  return load_specification_stream(stream, filedesc)

const BaseDatatypes* = [
  "integer", "unsigned_integer", "float", "string", "json"
]

proc is_compiled_stream(stream: Stream): bool =
  var magic_string = "        "
  discard stream.read_data_str(magic_string, 0..7)
  return magic_string == TFS_MAGIC_STRING

proc is_compiled_buffer*(buffer: string): bool =
  let stream = newStringStream(buffer)
  defer: stream.close()
  return is_compiled_stream(stream)

proc is_compiled*(specfile: string): bool =
  if not fileExists(specfile):
    raise newException(TextFormatsRuntimeError,
                       "Error reading specification data:\n" &
                       &"  File not found: '{specfile}'\n")
  var errmsg = ""
  try:
    let stream = newFileStream(specfile, mode = fmRead)
    defer: stream.close()
    return is_compiled_stream(stream)
  except IOError:
    errmsg = "Error loading specification\n" &
             &"  Filename: '{specfile}'\n" &
             getCurrentExceptionMsg().indent(2)
  raise newException(TextFormatsRuntimeError, errmsg)

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
