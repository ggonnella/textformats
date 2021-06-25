import jsonwrap
export jsonwrap
from json import `$`, parse_json, JsonNode
from textformats import nil
from textformats import DatatypeDefinition, Specification
export DatatypeDefinition
export Specification

proc parse_specification*(filename: cstring): Specification {.exportc.} =
  textformats.parse_specification($filename)

proc save_specification*(datatypes: Specification, filename: cstring)
                          {.exportc.} =
  textformats.save_specification(datatypes, $filename)

proc load_specification*(filename: cstring): Specification {.exportc.} =
  textformats.load_specification($filename)

proc get_definition*(datatypes: Specification, datatype: cstring):
                     DatatypeDefinition {.exportc.} =
  textformats.get_definition(datatypes, $datatype)

# cstring => JsonNode

proc decode*(input: cstring, dd: DatatypeDefinition): JsonNode {.exportc.} =
  textformats.decode($input, dd)

proc to_json*(input: cstring, dd: DatatypeDefinition):
                     cstring {.exportc.} =
  ($textformats.decode($input, dd)).cstring

proc is_valid_encoded*(
       input: string, dd: DatatypeDefinition): bool {.exportc.} =
  textformats.is_valid(input, dd)

# JsonNode => cstring

proc encode*(obj: JsonNode, dd: DatatypeDefinition): string {.exportc.} =
  textformats.encode(obj, dd)

proc unsafe_encode*(obj: JsonNode, dd: DatatypeDefinition):
                                                     string {.exportc.} =
  textformats.unsafe_encode(obj, dd)

proc from_json*(json_str: string, dd: DatatypeDefinition):
                      string {.exportc.} =
  textformats.encode(parse_json(json_str), dd)

proc unsafe_from_json*(json_str: string, dd: DatatypeDefinition):
                      string {.exportc.} =
  textformats.unsafe_encode(parse_json(json_str), dd)

proc is_valid_decoded*(
       obj: JsonNode, dd: DatatypeDefinition): bool {.exportc.} =
  textformats.is_valid(obj, dd)
