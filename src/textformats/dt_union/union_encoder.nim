import json, tables, strformat, strutils, sequtils
import ../types / [datatype_definition, textformats_error]
import ../support / [json_support]
import ../encoder

proc unwrap(wrapped: JsonNode): (string, JsonNode) =
  let branch_name = to_seq(wrapped.get_fields.keys)[0]
  (branch_name, wrapped[branch_name])

proc wrapped_union_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  let expmsg = "Expected: wrapped value, " &
               "i.e. a mapping with one entry, with:\n" &
               " - key:   string, which one_of branch to use for encoding\n" &
               " - value: the unwrapped decoded value\n"
  if not value.is_object:
    raise newException(EncodingError,
            &"Error: value ({value}) is a '{describe_kind(value)}'\n" & expmsg)
  if len(value) != 1:
    raise newException(EncodingError,
            &"Error: wrapped value has {len(value)} entries\n" & expmsg)
  let (branch_name, unwrapped) = value.unwrap
  for i, c in dd.choices:
    if branch_name == dd.branch_names[i]:
      try: return unwrapped.encode(c)
      except EncodingError:
        raise newException(EncodingError,
                &"Error: invalid value '" &
                unwrapped & "' for type '" &
                branch_name & "'\n" &
                get_current_exception_msg().indent(2) & "\n")
  raise newException(EncodingError,
        &"Error: invalid branch name: '" & branch_name & "'\n" &
        &"Expected one of: {dd.branch_names}\n")

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
    let (branch_name, unwrapped) = value.unwrap
    for i, c in dd.choices:
      if branch_name == dd.branch_names[i]:
        return unwrapped.unsafe_encode(c)
    assert(false)
  else:
    for c in dd.choices:
      try: return value.unsafe_encode(c)
      except ValueError: continue
    assert(false)

