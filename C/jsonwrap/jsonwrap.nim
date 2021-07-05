from json import nil

type
  JsonNodeRef* = ref JsonNode # translated in C to "JsonNode*"
  # a struct is necessary, since aliases names are not exporting:
  JsonNode* {.exportc.} = object
    value*: json.JsonNode

# not exporting "kind" because enums cannot anyway be exported
proc describe_kind*(n: JsonNodeRef): cstring {.exportc.} =
  result = ($n.value.kind).cstring

proc newJString*(s: cstring): JsonNodeRef {.exportc.} =
  result = new JsonNodeRef
  result.value = json.newJString($s)
  GC_ref(result.value)

proc newJInt*(i: cint): JsonNodeRef {.exportc.} =
  result = new JsonNodeRef
  result.value = json.newJInt(i.BiggestInt)
  GC_ref(result.value)

proc newJFloat*(f: cfloat): JsonNodeRef {.exportc.} =
  result = new JsonNodeRef
  result.value = json.newJFloat(f.float)
  GC_ref(result.value)

proc newJBool*(b: bool): JsonNodeRef {.exportc.} =
  result = new JsonNodeRef
  result.value = json.newJBool(b)
  GC_ref(result.value)

proc newJNull*(): JsonNodeRef {.exportc.} =
  result = new JsonNodeRef
  result.value = json.newJNull()
  GC_ref(result.value)

proc newJObject*(): JsonNodeRef {.exportc.} =
  result = new JsonNodeRef
  result.value = json.newJObject()
  GC_ref(result.value)

proc newJArray*(): JsonNodeRef {.exportc.} =
  result = new JsonNodeRef
  result.value = json.newJArray()
  GC_ref(result.value)

proc getStr*(n: JsonNodeRef): cstring {.exportc.} =
  result = json.getStr(n.value).cstring

proc getInt*(n: JsonNodeRef): cint {.exportc.} =
  result = json.getInt(n.value).cint

proc getBiggestInt*(n: JsonNodeRef): cint {.exportc.} =
  result = json.getBiggestInt(n.value).cint

proc getFloat*(n: JsonNodeRef): cfloat {.exportc.} =
  result = json.getFloat(n.value).cfloat

proc getBool*(n: JsonNodeRef): bool {.exportc.} =
  result = json.getBool(n.value)

# getFields skipped

# getElems skipped

proc JArray_add*(father: JsonNodeRef, child: JsonNodeRef) {.exportc.} =
  json.add(father.value, child.value)

proc JObject_add*(father: JsonNodeRef, key: cstring,
                 val: JsonNodeRef) {.exportc.} =
  json.add(father.value, $key, val.value)

# % skipped
# == skipped
# hash skipped

proc len*(n: JsonNodeRef): cint {.exportc.} =
  result = json.len(n.value).cint

proc JObject_get*(n: JsonNodeRef, name: cstring): JsonNodeRef {.exportc.} =
  result = new JsonNodeRef
  result.value = json.`[]`(n.value, $name)
  GC_ref(result.value)

proc JArray_get*(n: JsonNodeRef, indevalue: cint): JsonNodeRef {.exportc.} =
  result = new JsonNodeRef
  result.value = json.`[]`(n.value, indevalue)
  GC_ref(result.value)

proc has_key*(n: JsonNodeRef, key: cstring): bool {.exportc.} =
  result = json.has_key(n.value, $key)

proc JObject_contains*(n: JsonNodeRef, key: cstring): bool {.exportc.} =
  result = json.contains(n.value, $key)

proc JArray_contains*(n: JsonNodeRef, val: JsonNodeRef): bool {.exportc.} =
  result = json.contains(n.value, val.value)

# {} skipped
# getOrDefault skipped
# {}= skipped

proc JObject_delete*(n: JsonNodeRef, key: cstring) {.exportc.} =
  json.delete(n.value, $key)

proc copy*(n: JsonNodeRef): JsonNodeRef {.exportc.} =
  result = new JsonNodeRef
  result.value = json.copy(n.value)
  GC_ref(result.value)

# escape... skipped
# pretty skipped
# toUgly skipped

proc to_string*(n: JsonNodeRef): cstring {.exportc.} =
  json.`$`(n.value).cstring

# parseJson buffer skipped

proc parseJson*(buffer: cstring): JsonNodeRef {.exportc.} =
  result = new JsonNodeRef
  result.value = json.parseJson($buffer)
  GC_ref(result.value)

proc parseFile*(filename: cstring): JsonNodeRef {.exportc.} =
  result = new JsonNodeRef
  result.value = json.parseFile($filename)
  GC_ref(result.value)

proc delete_node*(n: JsonNodeRef) {.exportc.} =
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

# to skipped
# iterators skipped
# %* macro skipped
# % template skipped
