##
## This module shall be considered private. The public Python API
## is implemented in the textformats Python module (which imports this module
## using nimporter).
##
## This module defines functions which wrap the Nim API by using nimpy and
## the {.exportpy.} pragma. Furthermore JsonNode parameters and return values
## are converted to/from PyObject.
##
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

proc parse_specification*(specdata: string):
                          Specification {.exportpy.} =
  textformats.parse_specification(specdata)

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

proc run_specification_testfile(spec: Specification, testfile: string)
                                {.exportpy.} =
  textformats.run_specification_testfile(spec, testfile)

proc run_specification_tests(spec: Specification, testdata: string)
                             {.exportpy.} =
  textformats.run_specification_tests(spec, testdata)

proc datatype_names(spec: Specification): seq[string] {.exportpy.} =
  textformats.datatype_names(spec)

proc decode*(input: string, dd: DatatypeDefinition): JsonNode {.exportpy.} =
  textformats.decode(input, dd)

proc decode_to_json*(input: string, dd: DatatypeDefinition):
                    string {.exportpy.} =
  $textformats.decode(input, dd)

proc encode*(obj: PyObject, dd: DatatypeDefinition): string {.exportpy.} =
  textformats.encode(obj.to_json, dd)

proc encode_json*(json_str: string, dd: DatatypeDefinition):
                  string {.exportpy.} =
  textformats.encode(parse_json(json_str), dd)

proc is_valid_encoded*(
       input: string, dd: DatatypeDefinition): bool {.exportpy.} =
  textformats.is_valid(input, dd)

proc is_valid_decoded*(
       obj: PyObject, dd: DatatypeDefinition): bool {.exportpy.} =
  textformats.is_valid(obj.to_json, dd)

proc is_valid_decoded_json*(
       json_str: string, dd: DatatypeDefinition): bool {.exportpy.} =
  textformats.is_valid(parse_json(json_str), dd)

iterator decoded_file*(filename: string, dd: DatatypeDefinition,
                  embedded: bool = false, splitted: bool = false,
                  wrapped: bool = false): JsonNode {.exportpy.} =
  for decoded in textformats.decoded_file(filename, dd, embedded,
                                          splitted, wrapped):
    yield decoded

iterator decoded_file_as_json*(filename: string, dd: DatatypeDefinition,
                  embedded: bool = false, splitted: bool = false,
                  wrapped: bool = false): string {.exportpy.} =
  for decoded in textformats.decoded_file(filename, dd, embedded,
                                          splitted, wrapped):
    yield $decoded

proc get_unitsize(dd: DatatypeDefinition): int {.exportpy.} =
  textformats.get_unitsize(dd)

proc get_scope(dd: DatatypeDefinition): string {.exportpy.} =
  textformats.get_scope(dd)

proc set_unitsize(dd: DatatypeDefinition, unitsize: int) {.exportpy.} =
  textformats.set_unitsize(dd, unitsize)

proc set_scope(dd: DatatypeDefinition, scope: string) {.exportpy.} =
  textformats.set_scope(dd, scope)
