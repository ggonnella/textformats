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
from json import JsonNode, `$`, parse_json, pretty
from textformats import Specification, DatatypeDefinition
from textformats import nil

proc get_definition*(datatypes: Specification,
                     datatype: string = "default"):
                     DatatypeDefinition {.exportpy.} =
  textformats.get_definition(datatypes, datatype)

proc describe*(dd: DatatypeDefinition): string {.exportpy.} =
  textformats.`$`(dd)

proc repr*(dd: DatatypeDefinition): string {.exportpy.} =
  textformats.repr(dd)

proc specification_from_file*(filename: string):
                              Specification {.exportpy.} =
  if not fileExists(filename):
    raise newException(textformats.TextFormatsRuntimeError,
                       "File not found:" & filename)
  textformats.specification_from_file(filename)

proc parse_specification*(specdata: string):
                          Specification {.exportpy.} =
  textformats.parse_specification(specdata)

proc compile_specification*(inputfile: string, outputfile: string)
                              {.exportpy.} =
  if not fileExists(inputfile):
    raise newException(textformats.TextFormatsRuntimeError,
                       "File not found:" & inputfile)
  textformats.compile_specification(inputfile, outputfile)

proc is_compiled*(filename: string): bool {.exportpy.} =
  if not fileExists(filename):
    raise newException(textformats.TextFormatsRuntimeError,
                       "File not found:" & filename)
  textformats.is_compiled(filename)

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
  pretty(textformats.decode(input, dd))

proc encode*(obj: PyObject, dd: DatatypeDefinition): string {.exportpy.} =
  textformats.encode(obj.to(JsonNode), dd)

proc encode_json*(json_str: string, dd: DatatypeDefinition):
                  string {.exportpy.} =
  textformats.encode(parse_json(json_str), dd)

proc is_valid_encoded*(
       input: string, dd: DatatypeDefinition): bool {.exportpy.} =
  textformats.is_valid(input, dd)

proc is_valid_decoded*(
       obj: PyObject, dd: DatatypeDefinition): bool {.exportpy.} =
  textformats.is_valid(obj.to(JsonNode), dd)

proc is_valid_decoded_json*(
       json_str: string, dd: DatatypeDefinition): bool {.exportpy.} =
  textformats.is_valid(parse_json(json_str), dd)

type WrappedDecodedProcessorData = ref object
  processor: proc(n: JsonNode, data: PyObject)
  data: PyObject

proc wrapped_decoded_processor(n: JsonNode, data: pointer) =
  let
    wdata = cast[WrappedDecodedProcessorData](data)
    pydata = cast[PyObject](wdata.data)
  wdata.processor(n, pydata)

proc to_dpl(decoded_processor_level: int):
  textformats.DecodedProcessorLevel =
    case decoded_processor_level:
    of 0, 1, 2: textformats.DecodedProcessorLevel(decoded_processor_level)
    else:
      raise newException(textformats.TextFormatsRuntimeError,
              "Invalid decoded processor level\n" &
              "Expected: 0, 1 or 2\nFound: " & $decoded_processor_level)

proc decode_file*(filename: string, dd: DatatypeDefinition,
                    skip_embedded_spec: bool,
                     decoded_processor:
                        proc(n: JsonNode, d: PyObject),
                     decoded_processor_data: PyObject,
                     decoded_processor_level: int) {.exportpy.} =
  let
    wdata = WrappedDecodedProcessorData(processor: decoded_processor,
                                        data: decoded_processor_data)
  textformats.decode_file(filename, dd, skip_embedded_spec,
                          wrapped_decoded_processor,
                          cast[pointer](wdata),
                          to_dpl(decoded_processor_level))

type WrappedDecodedToJsonProcessorData = ref object
  processor: proc(s: string, data: PyObject)
  data: PyObject

proc wrapped_decoded_to_json_processor(n: JsonNode, data: pointer) =
  let
    wdata = cast[WrappedDecodedToJsonProcessorData](data)
    pydata = cast[PyObject](wdata.data)
  wdata.processor($n, pydata)

proc decode_file_to_json*(filename: string,
                             dd: DatatypeDefinition,
                             skip_embedded_spec: bool,
                             decoded_processor:
                               proc (s: string, data: PyObject),
                             decoded_processor_data: PyObject,
                             decoded_processor_level: int) {.exportpy.} =
  let
    wdata = WrappedDecodedToJsonProcessorData(processor: decoded_processor,
                                              data: decoded_processor_data)
  textformats.decode_file(filename, dd, skip_embedded_spec,
                          wrapped_decoded_to_json_processor,
                          cast[pointer](wdata),
                          to_dpl(decoded_processor_level))

iterator decoded_file*(filename: string, dd: DatatypeDefinition,
                  skip_embedded_spec: bool = false, as_elements: bool = false):
                    JsonNode {.exportpy.} =
  for decoded in textformats.decoded_file(filename, dd, skip_embedded_spec,
                                          as_elements):
    yield decoded

iterator decoded_file_to_json*(filename: string, dd: DatatypeDefinition,
                  skip_embedded_spec: bool = false,
                  yield_elements: bool = false):
                    string {.exportpy.} =
  for decoded in textformats.decoded_file(filename, dd, skip_embedded_spec,
                                          yield_elements):
    yield $decoded

proc get_unitsize(dd: DatatypeDefinition): int {.exportpy.} =
  textformats.get_unitsize(dd)

proc get_scope(dd: DatatypeDefinition): string {.exportpy.} =
  textformats.get_scope(dd)

proc set_unitsize(dd: DatatypeDefinition, unitsize: int) {.exportpy.} =
  textformats.set_unitsize(dd, unitsize)

proc set_scope(dd: DatatypeDefinition, scope: string) {.exportpy.} =
  textformats.set_scope(dd, scope)

proc get_wrapped(dd: DatatypeDefinition): bool {.exportpy.} =
  textformats.get_wrapped(dd)

proc set_wrapped(dd: DatatypeDefinition) {.exportpy.} =
  textformats.set_wrapped(dd)

proc unset_wrapped(dd: DatatypeDefinition) {.exportpy.} =
  textformats.unset_wrapped(dd)
