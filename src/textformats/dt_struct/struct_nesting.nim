import tables, strutils, json

proc normalize_struct_values*(value: JsonNode): JsonNode =
  result = newJObject()
  for k, v in value.pairs:
    # if k contains a dot, we need to split it up and created a nested object
    if k.contains('.'):
      let
        parts = k.split('.')
        last = parts[^1]
        first = parts[0..^2]
      var
        current = result
      for p in first:
        if not current.hasKey(p):
          current[p] = newJObject()
        current = current[p]
      current[last] = v
    else:
      result[k] = v

proc combine_nested_objects*(obj: JsonNode): JsonNode =
  # e.g. {"a": {"b": 1}} -> {"a.b": 1}
  result = newJObject()
  for k, v in obj.get_fields:
    if v.kind == JObject:
      for k2, v2 in v.get_fields:
        result[k & "." & k2] = v2
    else:
      result[k] = v
