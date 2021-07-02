import nimpy, os
from json import JsonNode, `$`, parse_json
from textformats import Specification, DatatypeDefinition
from textformats import nil

proc get_definition*(datatypes: Specification,
                     datatype: string = "default"):
                     DatatypeDefinition {.exportpy.} =
  textformats.get_definition(datatypes, datatype)

proc describe*(dd: DatatypeDefinition): string {.exportpy.} =
  textformats.`$`(dd)

proc specification_from_file*(filename: string):
                              Specification {.exportpy.} =
  if not fileExists(filename):
    raise newException(textformats.TextformatsRuntimeError,
                       "File not found:" & filename)
  textformats.specification_from_file(filename)

proc preprocess_specification*(inputfile: string, outputfile: string)
                              {.exportpy.} =
  if not fileExists(inputfile):
    raise newException(textformats.TextformatsRuntimeError,
                       "File not found:" & inputfile)
  textformats.preprocess_specification(inputfile, outputfile)

proc is_preprocessed*(filename: string): bool {.exportpy.} =
  if not fileExists(filename):
    raise newException(textformats.TextformatsRuntimeError,
                       "File not found:" & filename)
  textformats.is_preprocessed(filename)

proc decode*(input: string, dd: DatatypeDefinition): JsonNode {.exportpy.} =
  textformats.decode(input, dd)

proc to_json*(input: string, dd: DatatypeDefinition): string {.exportpy.} =
  $textformats.decode(input, dd)

proc encode*(obj: PyObject, dd: DatatypeDefinition): string {.exportpy.} =
  textformats.encode(obj.to_json, dd)

proc unsafe_encode*(obj: PyObject,
                    dd: DatatypeDefinition): string {.exportpy.} =
  textformats.unsafe_encode(obj.to_json, dd)

proc from_json*(json_str: string, dd: DatatypeDefinition): string {.exportpy.} =
  textformats.encode(parse_json(json_str), dd)

proc unsafe_from_json*(json_str: string,
                       dd: DatatypeDefinition): string {.exportpy.} =
  textformats.unsafe_encode(parse_json(json_str), dd)

proc is_valid_encoded*(
       input: string, dd: DatatypeDefinition): bool {.exportpy.} =
  textformats.is_valid(input, dd)

proc is_valid_decoded*(
       obj: PyObject, dd: DatatypeDefinition): bool {.exportpy.} =
  textformats.is_valid(obj.to_json, dd)

proc is_valid_decoded_json*(
       json_str: string, dd: DatatypeDefinition): bool {.exportpy.} =
  textformats.is_valid(parse_json(json_str), dd)

iterator decoded_file_values*(filename: string, dd: DatatypeDefinition,
                  embedded: bool = false, scope: string = "auto",
                  elemwise: bool = false, wrapped: bool = false,
                  unitsize: int = 1): JsonNode {.exportpy.} =
  for decoded in textformats.decoded_file_values(filename, dd, embedded, scope,
                                                 elemwise, wrapped, unitsize):
    yield decoded

iterator file_values_to_json*(filename: string, dd: DatatypeDefinition,
                  embedded: bool = false, scope: string = "auto",
                  elemwise: bool = false, wrapped: bool = false,
                  unitsize: int = 1): string {.exportpy.} =
  for decoded in textformats.decoded_file_values(filename, dd, embedded, scope,
                                                 elemwise, wrapped, unitsize):
    yield $decoded

proc test_specification(spec: Specification, testfile: string) {.exportpy.} =
  textformats.test_specification(spec, testfile)

proc datatype_names(spec: Specification): seq[string] {.exportpy.} =
  textformats.datatype_names(spec)

proc get_unitsize(dd: DatatypeDefinition): int {.exportpy.} =
  textformats.get_unitsize(dd)

proc get_scope(dd: DatatypeDefinition): string {.exportpy.} =
  textformats.get_scope(dd)
