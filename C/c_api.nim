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

# Errors handling

var
  tf_haderr  {.exportc.}: bool    = false
  tf_errname {.exportc.}: cstring = "".cstring
  tf_errmsg  {.exportc.}: cstring = "".cstring

template seterr() =
 tf_haderr  = true
 tf_errname = get_current_exception().name
 tf_errmsg  = get_current_exception_msg().cstring

template assert_no_failure(actions) =
  try:
    actions
  except:
    assert(false)

template on_failure_seterr_and_return(errval, actions) =
  try:
    actions
  except:
    seterr()
    return errval

template on_failure_seterr_and_return(actions) =
  on_failure_seterr_and_return(result, actions)

template on_failure_seterr(actions) =
  try:
    actions
  except:
    seterr()

proc unset_tf_err() {.exportc.} =
  tf_haderr = false
  tf_errname = "".cstring
  tf_errmsg = "".cstring

proc tf_printerr() {.exportc.} =
  stderr.write_line("Error (" & $tf_errname & "):\n" &
                    ($tf_errmsg).indent(2) & "\n")

proc tf_checkerr() {.exportc.} =
  if tf_haderr:
    tf_printerr()
    quit(1)

# Specifications

proc specification_from_file*(filename: cstring): SpecificationRef {.exportc.} =
  on_failure_seterr_and_return:
    if not fileExists($filename):
      raise newException(textformats.TextformatsRuntimeError,
                         "File not found:" & $filename)
    let spec = textformats.specification_from_file($filename)
    result = SpecificationRef(s: spec)
    GC_ref(result.s)

proc delete_specification*(datatypes: SpecificationRef) {.exportc.} =
  GC_unref(datatypes.s)

proc preprocess_specification*(inputfile: cstring, outputfile: cstring)
                              {.exportc.} =
  on_failure_seterr:
    if not fileExists($inputfile):
      raise newException(textformats.TextformatsRuntimeError,
                         "File not found:" & $inputfile)
    textformats.preprocess_specification($inputfile, $outputfile)

proc is_preprocessed*(filename: cstring): bool {.exportc.} =
  on_failure_seterr_and_return:
    if not fileExists($filename):
      raise newException(textformats.TextformatsRuntimeError,
                         "File not found:" & $filename)
    return textformats.is_preprocessed($filename)

proc test_specification(spec: SpecificationRef, testfile: cstring) {.exportc.} =
  on_failure_seterr:
    textformats.test_specification(spec.s, $testfile)

proc datatype_names(spec: SpecificationRef): cstring {.exportc.} =
  on_failure_seterr_and_return:
    return join(textformats.datatype_names(spec.s), " ").cstring

# Datatype definitions

proc get_definition*(datatypes: SpecificationRef, datatype: cstring):
                     DatatypeDefinitionRef {.exportc.} =
  on_failure_seterr_and_return:
    result = new DatatypeDefinitionRef
    result.value = textformats.get_definition(datatypes.s, $datatype)
    GC_ref(result.value)

proc delete_definition*(dd: DatatypeDefinitionRef) {.exportc.} =
  GC_unref(dd.value)

proc default_definition*(datatypes: SpecificationRef):
                         DatatypeDefinitionRef {.exportc.} =
  on_failure_seterr_and_return:
    result = get_definition(datatypes, "default")

proc describe*(dd: DatatypeDefinitionRef): cstring {.exportc.} =
  on_failure_seterr_and_return:
    result = (textformats.`$`(dd.value)).cstring

# Handling encoded strings

proc decode*(input: cstring, dd: DatatypeDefinitionRef):
             JsonNodeRef {.exportc, raises: [].} =
  on_failure_seterr_and_return:
    return JsonNodeRef(value: textformats.decode($input, dd.value))

proc to_json*(input: cstring, dd: DatatypeDefinitionRef):
              cstring {.exportc.} =
  on_failure_seterr_and_return:
    return ($textformats.decode($input, dd.value)).cstring

proc is_valid_encoded*(input: cstring, dd: DatatypeDefinitionRef):
                       bool {.exportc.} =
  on_failure_seterr_and_return:
    return textformats.is_valid($input, dd.value)

# Handling decoded data

proc encode*(obj: JsonNodeRef, dd: DatatypeDefinitionRef): cstring {.exportc.} =
  on_failure_seterr_and_return:
    return (textformats.encode(obj.value, dd.value)).cstring

proc unsafe_encode*(obj: JsonNodeRef, dd: DatatypeDefinitionRef):
                    cstring {.exportc.} =
  assert_no_failure:
    return (textformats.unsafe_encode(obj.value, dd.value)).cstring

proc is_valid_decoded*(
       obj: JsonNodeRef, dd: DatatypeDefinitionRef): bool {.exportc.} =
  on_failure_seterr_and_return:
    return textformats.is_valid(obj.value, dd.value)

# Handling decoded Json

proc from_json*(json_str: cstring, dd: DatatypeDefinitionRef):
                cstring {.exportc.} =
  on_failure_seterr_and_return:
    return (textformats.encode(parse_json($json_str), dd.value)).cstring

proc unsafe_from_json*(json_str: cstring, dd: DatatypeDefinitionRef):
                      cstring {.exportc.} =
  assert_no_failure:
    return (textformats.unsafe_encode(parse_json($json_str), dd.value)).cstring

proc is_valid_decoded_json*(
      json_str: cstring, dd: DatatypeDefinitionRef): bool {.exportc.} =
  on_failure_seterr_and_return:
    return textformats.is_valid(parse_json($json_str), dd.value)

# Handling encoded files

proc set_scope(dd: DatatypeDefinitionRef, scope: cstring) {.exportc.} =
  on_failure_seterr:
    textformats.set_scope(dd.value, $scope)

proc set_unitsize(dd: DatatypeDefinitionRef, unitsize: int) {.exportc.} =
  on_failure_seterr:
    textformats.set_unitsize(dd.value, unitsize)

proc set_wrapped(dd: DatatypeDefinitionRef) {.exportc.} =
  on_failure_seterr:
    textformats.set_wrapped(dd.value)

proc unset_wrapped(dd: DatatypeDefinitionRef) {.exportc.} =
  on_failure_seterr:
    textformats.unset_wrapped(dd.value)

proc get_wrapped*(dd: DatatypeDefinitionRef): bool {.exportc.} =
  on_failure_seterr_and_return:
    return textformats.get_wrapped(dd.value)

proc get_unitsize(dd: DatatypeDefinitionRef): int {.exportc.} =
  on_failure_seterr_and_return:
    return textformats.get_unitsize(dd.value)

proc get_scope(dd: DatatypeDefinitionRef): cstring {.exportc.} =
  on_failure_seterr_and_return:
    return (textformats.get_scope(dd.value)).cstring

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
  on_failure_seterr:
    for decoded in textformats.decoded_file_values($filename, dd.value,
                                                   embedded, $scope, elemwise,
                                                   wrapped, unitsize):
        deref_value_processor(decoded, cast[pointer](vp))

