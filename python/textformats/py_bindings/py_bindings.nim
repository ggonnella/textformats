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

iterator decoded_lines*(filename: string, dd: DatatypeDefinition,
                       embedded: bool = false, wrapped: bool = false):
                         JsonNode {.exportpy.} =
  for decoded in textformats.decoded_lines(filename, dd, embedded, wrapped):
    yield decoded

iterator decoded_units*(filename: string, dd: DatatypeDefinition, unitsize: int,
                        embedded: bool = false, wrapped: bool = false):
                         JsonNode {.exportpy.} =
  for decoded in textformats.decoded_units(filename, dd, unitsize,
                                           embedded, wrapped):
    yield decoded

iterator decoded_sections*(filename: string, dd: DatatypeDefinition,
                           embedded: bool = false): JsonNode {.exportpy.} =
  for decoded in textformats.decoded_sections(filename, dd, embedded):
    yield decoded

##export decode_file
##export decode_file_section_lines
##export test_specification
