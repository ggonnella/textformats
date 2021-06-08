import json, strformat

type JsonNodeKindError* = object of CatchableError

proc validate_kind*(n: JsonNode, k: JsonNodeKind) =
  if n.kind != k:
    raise newException(JsonNodeKindError,
                       &"Element kind should be {k} but is {n.kind}")

converter to_int*(n: JsonNode):    int    = n.to(int)
converter to_float*(n: JsonNode):  float  = n.to(float)
converter to_bool*(n: JsonNode):   bool   = n.to(bool)
converter to_string*(n: JsonNode): string = n.to(string)

template is_array*(n: JsonNode):    bool = n.kind == JArray
template is_object*(n: JsonNode):   bool = n.kind == JObject
template is_bool*(n: JsonNode):     bool = n.kind == JBool
template is_float*(n: JsonNode):    bool = n.kind == JFloat
template is_int*(n: JsonNode):      bool = n.kind == JInt
template is_uint*(n: JsonNode):     bool = n.kind == JInt and n.to_int >= 0
template is_null*(n: JsonNode):     bool = n.kind == JNull
template is_string*(n: JsonNode):   bool = n.kind == JString
template is_compound*(n: JsonNode): bool = n.is_array or n.is_object
template is_scalar*(n: JsonNode):   bool = not is_compound(n)

proc describe_kind*(n: JsonNode): string =
  result = "Value is "
  case n.kind:
    of JArray:
      result &= "an array"
    of JObject:
      result &= "a dictionary"
    of JBool:
      result &= "a boolean"
    of JFloat:
      result &= "a float"
    of JInt:
      if n.to_int < 0:
        result &= "a negative integer"
      else:
        result &= "an integer"
    of JNull:
      result &= "null"
    of JString:
      result &= "a string"
