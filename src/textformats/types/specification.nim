import tables, marshal, strformat
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
                       "Error while saving specification file '{filename}'\n" &
                       e.msg)

proc load_specification*(filename: string): Specification =
  try:
    filename.readFile().to[:Specification]
  except IOError:
    let e = get_current_exception()
    raise newException(TextformatsRuntimeError,
                       "Error while loading specification file '{filename}'\n" &
                       e.msg)

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
