import os, strutils
import jsonwrap
export jsonwrap
import error_handling
export error_handling
from json import `$`, parse_json
from textformats import nil
discard textformats.avoid_module_unused_warning

type
  SpecificationRef = ref Specification # in C: Specification*
  # aliases are not exported, thus a struct:
  Specification* {.exportc.} = object
    s: textformats.Specification
  DatatypeDefinitionRef = ref DatatypeDefinition # in C: DatatypeDefinition*
  # aliases are not exported, thus a struct:
  DatatypeDefinition* {.exportc.} = object
    value: textformats.DatatypeDefinition

# Specifications

proc tf_specification_from_file*(filename: cstring):
                                 SpecificationRef {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    if not fileExists($filename):
      raise newException(textformats.TextFormatsRuntimeError,
                         "File not found:" & $filename)
    let spec = textformats.specification_from_file($filename)
    result = SpecificationRef(s: spec)
    GC_ref(result.s)

proc tf_parse_specification*(input: cstring):
                             SpecificationRef {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    let spec = textformats.parse_specification($input)
    result = SpecificationRef(s: spec)
    GC_ref(result.s)

proc tf_delete_specification*(datatypes: SpecificationRef)
                             {.exportc, raises: [].} =
  assert_no_failure:
    GC_unref(datatypes.s)

proc tf_preprocess_specification*(inputfile: cstring, outputfile: cstring)
                              {.exportc, raises: [].} =
  on_failure_seterr:
    if not fileExists($inputfile):
      raise newException(textformats.TextFormatsRuntimeError,
                         "File not found:" & $inputfile)
    textformats.preprocess_specification($inputfile, $outputfile)

proc tf_is_preprocessed*(filename: cstring): bool {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    if not fileExists($filename):
      raise newException(textformats.TextFormatsRuntimeError,
                         "File not found:" & $filename)
    return textformats.is_preprocessed($filename)

proc tf_run_specification_testfile(spec: SpecificationRef, testfile: cstring)
                          {.exportc, raises: [].} =
  on_failure_seterr:
    textformats.run_specification_testfile(spec.s, $testfile)

proc tf_run_specification_tests(spec: SpecificationRef, testdata: cstring)
                          {.exportc, raises: [].} =
  on_failure_seterr:
    textformats.run_specification_tests(spec.s, $testdata)

proc tf_datatype_names(spec: SpecificationRef):
                       cstring {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    return join(textformats.datatype_names(spec.s), " ").cstring

# Datatype definitions

proc tf_get_definition*(datatypes: SpecificationRef, datatype: cstring):
                        DatatypeDefinitionRef {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    result = new DatatypeDefinitionRef
    result.value = textformats.get_definition(datatypes.s, $datatype)
    GC_ref(result.value)

proc tf_delete_definition*(dd: DatatypeDefinitionRef) {.exportc, raises: [].} =
  assert_no_failure:
    GC_unref(dd.value)

proc tf_default_definition*(datatypes: SpecificationRef):
                         DatatypeDefinitionRef {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    result = tf_get_definition(datatypes, "default")

proc tf_describe*(dd: DatatypeDefinitionRef): cstring {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    result = (textformats.`$`(dd.value)).cstring

# Handling encoded strings

proc tf_decode*(input: cstring, dd: DatatypeDefinitionRef):
             JsonNodeRef {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    return JsonNodeRef(value: textformats.decode($input, dd.value))

proc tf_decode_to_json*(input: cstring, dd: DatatypeDefinitionRef):
              cstring {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    return ($(textformats.decode($input, dd.value))).cstring

proc tf_is_valid_encoded*(input: cstring, dd: DatatypeDefinitionRef):
                       bool {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    return textformats.is_valid($input, dd.value)

# Handling decoded data

proc tf_encode*(obj: JsonNodeRef, dd: DatatypeDefinitionRef):
                cstring {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    return (textformats.encode(obj.value, dd.value)).cstring

proc tf_is_valid_decoded*(obj: JsonNodeRef, dd: DatatypeDefinitionRef):
                         bool {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    return textformats.is_valid(obj.value, dd.value)

# Handling decoded Json

proc tf_encode_json*(json_str: cstring, dd: DatatypeDefinitionRef):
                cstring {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    return (textformats.encode(
              json.parse_json($json_str), dd.value)).cstring

proc tf_is_valid_decoded_json*(json_str: cstring, dd: DatatypeDefinitionRef):
                              bool {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    return textformats.is_valid(json.parse_json($json_str), dd.value)

# Handling encoded files

proc tf_set_scope(dd: DatatypeDefinitionRef, scope: cstring)
                 {.exportc, raises: [].} =
  on_failure_seterr:
    textformats.set_scope(dd.value, $scope)

proc tf_set_unitsize(dd: DatatypeDefinitionRef, unitsize: int)
                    {.exportc, raises: [].} =
  on_failure_seterr:
    textformats.set_unitsize(dd.value, unitsize)

proc tf_set_wrapped(dd: DatatypeDefinitionRef) {.exportc, raises: [].} =
  on_failure_seterr:
    textformats.set_wrapped(dd.value)

proc tf_unset_wrapped(dd: DatatypeDefinitionRef) {.exportc, raises: [].} =
  on_failure_seterr:
    textformats.unset_wrapped(dd.value)

proc tf_get_wrapped*(dd: DatatypeDefinitionRef): bool {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    return textformats.get_wrapped(dd.value)

proc tf_get_unitsize(dd: DatatypeDefinitionRef): int {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    return textformats.get_unitsize(dd.value)

proc tf_get_scope(dd: DatatypeDefinitionRef): cstring {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    return (textformats.get_scope(dd.value)).cstring

#
# decoded_processor_level for scope section/file:
# 0: whole section/file at once
# 1: each element of outermost definition
# 2: single lines
#

type WrappedDecodedProcessorData = ref object
  processor: proc(n: JsonNodeRef, data: pointer) {.cdecl.}
  data: pointer
  refnode: JsonNodeRef

proc wrapped_decoded_processor(n: json.JsonNode, data: pointer) =
  # The C code does not see the JsonNode instance, but a JsonNodeRef
  # instance instead (defined in jsonwrap); this processor function is used
  # internally as an adapter to the correct processing function type
  # (which accesses the JsonNode instead of the JsonNodeRef).
  let wdata = cast[WrappedDecodedProcessorData](data)
  wdata.refnode.value = n
  wdata.processor(wdata.refnode, wdata.data)

proc to_dpl(decoded_processor_level: int):
  textformats.DecodedProcessorLevel =
    case decoded_processor_level:
    of 0, 1, 2: textformats.DecodedProcessorLevel(decoded_processor_level)
    else:
      raise newException(textformats.TextFormatsRuntimeError,
              "Invalid decoded processor level\n" &
              "Expected: 0, 1 or 2\nFound: " & $decoded_processor_level)

proc tf_decode_file*(filename: cstring, skip_embedded_spec: bool,
                     dd: DatatypeDefinitionRef,
                     decoded_processor:
                       proc (n: JsonNodeRef, data: pointer) {.cdecl.},
                     decoded_processor_data: pointer,
                     decoded_processor_level: int) {.exportc, raises: [].} =
  let
    wdata = WrappedDecodedProcessorData(processor: decoded_processor,
                                        data: decoded_processor_data,
                                        refnode: new JsonNodeRef)
  on_failure_seterr:
    textformats.decode_file($filename, dd.value, skip_embedded_spec,
                            wrapped_decoded_processor, cast[pointer](wdata),
                            to_dpl(decoded_processor_level))

type WrappedDecodedToJsonProcessorData = ref object
  processor: proc(s: cstring, data: pointer) {.cdecl.}
  data: pointer

proc wrapped_decoded_to_json_processor(n: json.JsonNode, data: pointer) =
  let wdata = cast[WrappedDecodedToJsonProcessorData](data)
  wdata.processor(($n).cstring, wdata.data)

proc tf_decode_file_to_json*(filename: cstring, skip_embedded_spec: bool,
                             dd: DatatypeDefinitionRef,
                             decoded_processor:
                               proc (s: cstring, data: pointer) {.cdecl.},
                             decoded_processor_data: pointer,
                             decoded_processor_level: int)
                             {.exportc, raises: [].} =
  let
    wdata = WrappedDecodedToJsonProcessorData(processor: decoded_processor,
                                              data: decoded_processor_data)
  on_failure_seterr:
    textformats.decode_file($filename, dd.value, skip_embedded_spec,
                            wrapped_decoded_to_json_processor,
                            cast[pointer](wdata),
                            to_dpl(decoded_processor_level))

