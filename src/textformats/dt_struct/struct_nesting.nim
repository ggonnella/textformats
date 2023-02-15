import tables, strutils, json
import ../types/datatype_definition

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

proc pass_keys_to_children*(value: JsonNode,
                           dd: DatatypeDefinition): JsonNode =
  # e.g. {"b": 1} -> {"a": {"b": 1}}
  result = newJObject()
  var assign = newTable[string, string]()
  for m in dd.members:
    if m.name in dd.merge_keys:
      if m.def.kind == ddkStruct:
        for m2 in m.def.members:
          assign[m2.name] = m.name
        result[m.name] = newJObject()
  for k, v in value.pairs:
    if k in assign:
      result[assign[k]][k] = v
    else:
      result[k] = v

proc merge_keys_with_parent*(value: JsonNode,
                            dd: DatatypeDefinition): JsonNode =
  # e.g. {"a": {"b": 1}} -> {"b": 1}
  result = newJObject()
  for k, v in value.pairs:
    if k in dd.merge_keys:
      for k2, v2 in v.pairs:
        result[k2] = v2
    else:
      result[k] = v
