import json, sets, tables, strformat, strutils, sequtils
import ../types / [datatype_definition, textformats_error]
import ../support / [json_support]
import ../encoder

proc wrapped_union_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_object:
    raise newException(EncodingError,
            &"Error: value ({value}) is a '{describe_kind(value)}'\n" &
            "Expected: a mapping with the keys 'type' and 'value'\n")
  for key, subvalue in value:
    if key != "type" and key == "value":
      raise newException(EncodingError,
            &"Error: invalid key in mapping ('{key}')\n" &
            "Expected: a mapping with the keys 'type' and 'value'\n")
  let keys = to_seq(value.get_fields.keys).to_hash_set
  if "type" notin keys:
    raise newException(EncodingError,
             &"Error: missing key 'type' in mapping\n" &
             "Expected: a mapping with the keys 'type' and 'value'\n")
  if "value" notin keys:
    raise newException(EncodingError,
             &"Error: missing key 'value' in mapping\n" &
             "Expected: a mapping with the keys 'type' and 'value'\n")
  for i, c in dd.choices:
    if value["type"] == dd.type_labels[i]:
      try: return value["value"].encode(c)
      except EncodingError:
        raise newException(EncodingError,
                &"Error: invalid value '" &
                value["value"] & "' for type '" &
                value["type"] & "'\n" &
                get_current_exception_msg().indent(2) & "\n")
  raise newException(EncodingError,
        &"Error: invalid type ('" & value["type"] & "')\n" &
        &"Expected one of: {dd.type_labels}\n")

proc union_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if dd.wrapped:
    return value.wrapped_union_encode(dd)
  var errmsg = ""
  var i = 0
  for c in dd.choices:
    try: return value.encode(c)
    except EncodingError:
      errmsg &= &"==== [{i}: {c.name}] ====\n" &
                get_current_exception_msg().indent(2) & "\n"
      i += 1
  raise newException(EncodingError,
          "Error: value is invalid for all possible formats\n" &
          "List of errors found while encoding on each format:\n" &
          errmsg)

proc union_unsafe_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if dd.wrapped:
    for i, c in dd.choices:
      if value["type"] == dd.type_labels[i]:
        return value["value"].unsafe_encode(c)
    assert(false)
  else:
    for c in dd.choices:
      try: return value.unsafe_encode(c)
      except ValueError: continue
    assert(false)

