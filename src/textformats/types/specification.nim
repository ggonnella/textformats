import tables, marshal, strformat, os, json
import datatype_definition, textformats_error

export pairs

type
  Specification* = TableRef[string, DatatypeDefinition]

proc save_specification*(table: Specification, filename: string) =
  try:
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
    return filecontent.to[:Specification]
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

proc get_definition*(datatypes: Specification,
                     datatype: string): DatatypeDefinition =
  try:
    datatypes[datatype]
  except KeyError:
    raise newException(TextformatsRuntimeError,
              &"The datatype '{datatype}' is not defined in the specification.")
