import os, strutils
import jsonwrap
export jsonwrap
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

proc get_definition*(datatypes: SpecificationRef, datatype: cstring):
                     DatatypeDefinitionRef {.exportc.} =
  result = new DatatypeDefinition
  result.value = textformats.get_definition(datatypes.s, $datatype)
  GC_ref(result.value)

proc delete_definition*(dd: DatatypeDefinitionRef) {.exportc.} =
  GC_unref(dd.value)

proc default_definition*(datatypes: SpecificationRef):
                         DatatypeDefinitionRef {.exportc.} =
  get_definition(datatypes, "default")

proc describe*(dd: DatatypeDefinitionRef): cstring {.exportc.} =
  (textformats.`$`(dd.value)).cstring

proc specification_from_file*(filename: cstring): SpecificationRef {.exportc.} =
  if not fileExists($filename):
    raise newException(textformats.TextformatsRuntimeError,
                       "File not found:" & $filename)
  result = new Specification
  result.s = textformats.specification_from_file($filename)
  GC_ref(result.s)

proc delete_specification*(datatypes: SpecificationRef) {.exportc.} =
  GC_unref(datatypes.s)

proc preprocess_specification*(inputfile: cstring, outputfile: cstring)
                              {.exportc.} =
  if not fileExists($inputfile):
    raise newException(textformats.TextformatsRuntimeError,
                       "File not found:" & $inputfile)
  textformats.preprocess_specification($inputfile, $outputfile)

proc is_preprocessed*(filename: cstring): bool {.exportc.} =
  if not fileExists($filename):
    raise newException(textformats.TextformatsRuntimeError,
                       "File not found:" & $filename)
  textformats.is_preprocessed($filename)

# cstring => JsonNode

proc decode*(input: cstring, dd: DatatypeDefinitionRef):
             JsonNodeRef {.exportc, raises: [].} =
  var decoded: json.JsonNode
  try:
    decoded = textformats.decode($input, dd.value)
  except textformats.DecodingError:
    return nil
  result = new JsonNodeRef
  result.value = decoded
  GC_ref(result.value)

proc to_json*(input: cstring, dd: DatatypeDefinitionRef):
              cstring {.exportc.} =
  ($textformats.decode($input, dd.value)).cstring

proc is_valid_encoded*(input: cstring, dd: DatatypeDefinitionRef):
                       bool {.exportc.} =
  textformats.is_valid($input, dd.value)

# JsonNode => cstring

proc encode*(obj: JsonNodeRef, dd: DatatypeDefinitionRef): cstring {.exportc.} =
  (textformats.encode(obj.value, dd.value)).cstring

proc unsafe_encode*(obj: JsonNodeRef, dd: DatatypeDefinitionRef):
                    cstring {.exportc.} =
  (textformats.unsafe_encode(obj.value, dd.value)).cstring

proc from_json*(json_str: cstring, dd: DatatypeDefinitionRef):
                cstring {.exportc.} =
  (textformats.encode(parse_json($json_str), dd.value)).cstring

proc unsafe_from_json*(json_str: cstring, dd: DatatypeDefinitionRef):
                      cstring {.exportc.} =
  (textformats.unsafe_encode(parse_json($json_str), dd.value)).cstring

proc is_valid_decoded*(
       obj: JsonNodeRef, dd: DatatypeDefinitionRef): bool {.exportc.} =
  textformats.is_valid(obj.value, dd.value)

proc is_valid_decoded_json*(
      json_str: cstring, dd: DatatypeDefinitionRef): bool {.exportc.} =
  textformats.is_valid(parse_json($json_str), dd.value)

proc test_specification(spec: SpecificationRef, testfile: cstring) {.exportc.} =
  textformats.test_specification(spec.s, $testfile)

proc datatype_names(spec: SpecificationRef): cstring {.exportc.} =
  join(textformats.datatype_names(spec.s), " ").cstring

proc get_unitsize(dd: DatatypeDefinitionRef): int {.exportc.} =
  textformats.get_unitsize(dd.value)

proc get_scope(dd: DatatypeDefinitionRef): cstring {.exportc.} =
  (textformats.get_scope(dd.value)).cstring

proc set_scope(dd: DatatypeDefinitionRef, scope: cstring) {.exportc.} =
  textformats.set_scope(dd.value, $scope)

proc set_unitsize(dd: DatatypeDefinitionRef, unitsize: int) {.exportc.} =
  textformats.set_unitsize(dd.value, unitsize)

proc set_wrapped(dd: DatatypeDefinitionRef) {.exportc.} =
  textformats.set_wrapped(dd.value)

proc unset_wrapped(dd: DatatypeDefinitionRef) {.exportc.} =
  textformats.unset_wrapped(dd.value)

proc get_wrapped*(dd: DatatypeDefinitionRef): bool {.exportc.} =
  textformats.get_wrapped(dd.value)

type ValueProcessor = ref object
  processor: proc(n: JsonNodeRef, data: pointer) {.cdecl.}
  data: pointer
  refnode: JsonNodeRef

proc deref_value_processor(n: json.JsonNode, data: pointer) =
  let vp = cast[ValueProcessor](data)
  vp.refnode.value = n
  vp.processor(vp.refnode, vp.data)

proc decode_file_values*(filename: cstring, embedded: bool,
                  dd: DatatypeDefinitionRef,
                  value_processor:
                    proc (n: JsonNodeRef, data: pointer) {.cdecl.},
                  value_processor_data: pointer,
                  elemwise: bool = false) {.exportc.} =
  let
    scope = dd.get_scope
    unitsize = dd.get_unitsize
    wrapped = dd.get_wrapped
    vp = ValueProcessor(processor: value_processor,
                            data: value_processor_data,
                            refnode: new JsonNodeRef)
  for decoded in textformats.decoded_file_values($filename, dd.value, embedded,
                                                 $scope, elemwise, wrapped,
                                                 unitsize):
    deref_value_processor(decoded, cast[pointer](vp))

