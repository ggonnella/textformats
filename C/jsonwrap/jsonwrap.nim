from json import nil

type
  JsonNodeKind = json.JsonNodeKind
  JsonNode = json.JsonNode

proc kind(n: JsonNode): JsonNodeKind {.exportc.} =
  n.kind

proc kind_to_string(n: JsonNode): cstring {.exportc.} =
  result = ($n.kind).cstring

proc newJString(s: cstring): JsonNode {.exportc.} =
  result = json.newJString($s)
  GC_ref(result)

proc newJInt(n: cint): JsonNode {.exportc.} =
  result = json.newJInt(n.BiggestInt)
  GC_ref(result)

proc newJFloat(n: cfloat): JsonNode {.exportc.} =
  result = json.newJFloat(n.float)
  GC_ref(result)

proc newJBool(b: bool): JsonNode {.exportc.} =
  result = json.newJBool(b)
  GC_ref(result)

proc newJNull(): JsonNode {.exportc.} =
  result = json.newJNull()
  GC_ref(result)

proc newJObject(): JsonNode {.exportc.} =
  result = json.newJObject()
  GC_ref(result)

proc newJArray(): JsonNode {.exportc.} =
  result = json.newJArray()
  GC_ref(result)

proc getStr(n: JsonNode): cstring {.exportc.} =
  result = json.getStr(n).cstring

proc getInt(n: JsonNode): cint {.exportc.} =
  result = json.getInt(n).cint

proc getBiggestInt(n: JsonNode): cint {.exportc.} =
  result = json.getBiggestInt(n).cint

proc getFloat(n: JsonNode): cfloat {.exportc.} =
  result = json.getFloat(n).cfloat

proc getBool(n: JsonNode): bool {.exportc.} =
  result = json.getBool(n)

# getFields skipped

# getElems skipped

proc JArray_add(father: JsonNode, child: JsonNode) {.exportc.} =
  json.add(father, child)

proc JObject_add(father: JsonNode, key: cstring, val: JsonNode) {.exportc.} =
  json.add(father, $key, val)

# % skipped
# == skipped
# hash skipped

proc len(n: JsonNode): cint {.exportc.} =
  result = json.len(n).cint

proc JObject_get(n: JsonNode, name: cstring): JsonNode {.exportc.} =
  result = json.`[]`(n, $name)
  GC_ref(result)

proc JArray_get(n: JsonNode, index: cint): JsonNode {.exportc.} =
  result = json.`[]`(n, index)
  GC_ref(result)

proc has_key(node: JsonNode, key: cstring): bool {.exportc.} =
  result = json.has_key(node, $key)

proc JObject_contains(node: JsonNode, key: cstring): bool {.exportc.} =
  result = json.contains(node, $key)

proc JArray_contains(node: JsonNode, val: JsonNode): bool {.exportc.} =
  result = json.contains(node, val)

# {} skipped
# getOrDefault skipped
# {}= skipped

proc JObject_delete(obj: JsonNode, key: cstring) {.exportc.} =
  json.delete(obj, $key)

proc copy(p: JsonNode): JsonNode {.exportc.} =
  result = json.copy(p)
  GC_ref(result)

# escape... skipped
# pretty skipped
# toUgly skipped

proc to_string(node: JsonNode): cstring {.exportc.} =
  result = json.`$`(node).cstring

# parseJson buffer skipped

proc parseJson(buffer: cstring): JsonNode {.exportc.} =
  result = json.parseJson($buffer)
  GC_ref(result)

proc parseFile(filename: cstring): JsonNode {.exportc.} =
  result = json.parseFile($filename)
  GC_ref(result)

proc GC_unref_node(n: JsonNode) {.exportc.} =
  GC_unref(n)

# to skipped
# iterators skipped
# %* macro skipped
# % template skipped
