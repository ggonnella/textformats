import nimpy
from json import JsonNode, `$`, parse_json
from textformats import Specification, DatatypeDefinition
from textformats import nil

proc get_definition*(datatypes: Specification,
                     datatype: string):
                     DatatypeDefinition {.exportpy.} =
  textformats.get_definition(datatypes, datatype)

proc parse_specification*(filename: string):
                                 Specification {.exportpy.} =
  textformats.parse_specification(filename)

proc decode*(input: string, dd: DatatypeDefinition): JsonNode {.exportpy.} =
  textformats.decode(input, dd)

proc recognize_and_decode*(input: string, dd: DatatypeDefinition):
                           tuple[name: string, decoded: JsonNode] {.exportpy.} =
  textformats.recognize_and_decode(input, dd)

proc to_json*(input: string, dd: DatatypeDefinition):
                     string {.exportpy.} =
  $textformats.decode(input, dd)

proc encode*(obj: PyObject, dd: DatatypeDefinition): string {.exportpy.} =
  textformats.encode(obj.to_json, dd)

proc unsafe_encode*(obj: PyObject, dd: DatatypeDefinition):
                                                     string {.exportpy.} =
  textformats.unsafe_encode(obj.to_json, dd)

proc from_json*(json_str: string, dd: DatatypeDefinition):
                      string {.exportpy.} =
  textformats.encode(parse_json(json_str), dd)

proc unsafe_from_json*(json_str: string, dd: DatatypeDefinition):
                      string {.exportpy.} =
  textformats.unsafe_encode(parse_json(json_str), dd)

proc is_valid_encoded*(
       input: string, dd: DatatypeDefinition): bool {.exportpy.} =
  textformats.is_valid(input, dd)

proc is_valid_decoded*(
       obj: PyObject, dd: DatatypeDefinition): bool {.exportpy.} =
  textformats.is_valid(obj.to_json, dd)
