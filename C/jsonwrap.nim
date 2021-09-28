##
## This module wraps functions of the Nim JSON module and exports them to C
##
import sequtils
import error_handling
from json import nil

type
  JsonNodeRef* = ref JsonNode # translated in C to "JsonNode*"
  # a struct is necessary, since aliases names are not exporting:
  JsonNode* {.exportc.} = object
    value*: json.JsonNode

proc jsonnode_kind(n: JsonNodeRef): int {.exportc, raises: [].} =
  case n.value.kind:
  of json.JNull:    0
  of json.JBool:    1
  of json.JInt:     2
  of json.JFloat:   3
  of json.JString:  4
  of json.JArray:   5
  of json.JObject:  6

proc jsonnode_describe_kind*(n: JsonNodeRef): cstring {.exportc, raises: [].} =
  result = ($n.value.kind).cstring

proc new_j_null*(): JsonNodeRef {.exportc, raises: [].} =
  result = new JsonNodeRef
  result.value = json.newJNull()
  GC_ref(result.value)

proc new_j_bool*(b: bool): JsonNodeRef {.exportc, raises: [].} =
  result = new JsonNodeRef
  result.value = json.newJBool(b)
  GC_ref(result.value)

proc new_j_int*(i: cint): JsonNodeRef {.exportc, raises: [].} =
  result = new JsonNodeRef
  result.value = json.newJInt(i.BiggestInt)
  GC_ref(result.value)

proc new_j_float*(f: cfloat): JsonNodeRef {.exportc, raises: [].} =
  result = new JsonNodeRef
  result.value = json.newJFloat(f.float)
  GC_ref(result.value)

proc new_j_string*(s: cstring): JsonNodeRef {.exportc, raises: [].} =
  result = new JsonNodeRef
  result.value = json.newJString($s)
  GC_ref(result.value)

proc new_j_object*(): JsonNodeRef {.exportc, raises: [].} =
  result = new JsonNodeRef
  result.value = json.newJObject()
  GC_ref(result.value)

proc new_j_array*(): JsonNodeRef {.exportc, raises: [].} =
  result = new JsonNodeRef
  result.value = json.newJArray()
  GC_ref(result.value)

proc j_array_add*(father: JsonNodeRef, child: JsonNodeRef)
                  {.exportc, raises: [].} =
  json.add(father.value, child.value)

proc j_object_add*(father: JsonNodeRef, key: cstring,
                 val: JsonNodeRef) {.exportc, raises: [].} =
  json.add(father.value, $key, val.value)

proc j_bool_get*(n: JsonNodeRef): bool {.exportc, raises: [].} =
  result = json.getBool(n.value)

proc j_int_get*(n: JsonNodeRef): cint {.exportc, raises: [].} =
  result = json.getBiggestInt(n.value).cint

proc j_float_get*(n: JsonNodeRef): cfloat {.exportc, raises: [].} =
  result = json.getFloat(n.value).cfloat

proc j_string_get*(n: JsonNodeRef): cstring {.exportc, raises: [].} =
  result = json.getStr(n.value).cstring

proc j_array_len*(n: JsonNodeRef): cint {.exportc, raises: [].} =
  result = json.len(n.value).cint

proc j_object_len*(n: JsonNodeRef): cint {.exportc, raises: [].} =
  result = json.len(n.value).cint

proc j_object_get_key*(n: JsonNodeRef, index: cint):
                       cstring {.exportc, raises: [].} =
  to_seq(json.keys(n.value))[index]

proc j_object_get*(n: JsonNodeRef, name: cstring):
                   JsonNodeRef {.exportc, raises: [].} =
  on_failure_seterr_and_return(nil):
    result = new JsonNodeRef
    result.value = json.`[]`(n.value, $name)
    GC_ref(result.value)

proc j_array_get*(n: JsonNodeRef, index: cint):
                  JsonNodeRef {.exportc, raises: [].} =
  result = new JsonNodeRef
  result.value = json.`[]`(n.value, index)
  GC_ref(result.value)

proc j_object_contains*(n: JsonNodeRef, key: cstring):
                        bool {.exportc, raises: [].} =
  result = json.contains(n.value, $key)

proc j_array_contains*(n: JsonNodeRef, val: JsonNodeRef):
                      bool {.exportc, raises: [].} =
  assert_no_failure:
    result = json.contains(n.value, val.value)

proc j_object_delete*(n: JsonNodeRef, key: cstring) {.exportc, raises: [].} =
  on_failure_seterr:
    json.delete(n.value, $key)

proc jsonnode_to_string*(n: JsonNodeRef): cstring {.exportc, raises: [].} =
  json.`$`(n.value).cstring

proc jsonnode_from_string*(buffer: cstring):
                           JsonNodeRef {.exportc, raises: [].} =
  on_failure_seterr:
    result = new JsonNodeRef
    result.value = json.parseJson($buffer)
    GC_ref(result.value)

proc jsonnode_from_file*(filename: cstring):
                         JsonNodeRef {.exportc, raises: [].} =
  on_failure_seterr:
    result = new JsonNodeRef
    result.value = json.parseFile($filename)
    GC_ref(result.value)

proc copy_jsonnode*(n: JsonNodeRef): JsonNodeRef {.exportc, raises: [].} =
  result = new JsonNodeRef
  result.value = json.copy(n.value)
  GC_ref(result.value)

proc delete_jsonnode*(n: JsonNodeRef) {.exportc, raises: [].} =
  let node = n.value
  GC_unref(node)

proc deep_delete_jsonnode*(n: JsonNodeRef) {.exportc, raises: [].} =
  let node = n.value
  case node.kind:
    of json.JObject:
      for k, v in json.pairs(node):
        GC_unref(v)
    of json.JArray:
      for elem in json.items(node):
        GC_unref(elem)
    else:
      discard
  GC_unref(node)

# % skipped
# == skipped
# hash skipped
# {} skipped
# getOrDefault skipped
# {}= skipped
# escape... skipped
# pretty skipped
# toUgly skipped
# to skipped
# iterators skipped
# %* macro skipped
# % template skipped
# parseJson buffer skipped
# getFields skipped
# getElems skipped

