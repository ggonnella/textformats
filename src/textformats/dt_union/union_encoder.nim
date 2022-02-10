import json, tables, strformat, strutils, sequtils
import ../types / [datatype_definition, textformats_error]
import ../support / [json_support]
import ../encoder

proc unwrap(wrapped: JsonNode): (string, JsonNode) =
  let branch_name = to_seq(wrapped.get_fields.keys)[0]
  (branch_name, wrapped[branch_name])

proc wrapped_union_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  let expmsg = "expected: wrapped {branch_name: value}\n"
  if not value.is_object:
    raise newException(EncodingError,
            &"Value ({value}) is a '{describe_kind(value)}', " & expmsg)
  if len(value) != 1:
    raise newException(EncodingError,
            &"Value has {len(value)} entries, " & expmsg)
  let (branch_name, unwrapped) = value.unwrap
  for i, c in dd.choices:
    if branch_name == dd.branch_names[i]:
      try: return unwrapped.encode(c)
      except EncodingError:
        let e = getCurrentException()
        e.msg = "Invalid value '" & unwrapped &
                "' for type '" & branch_name & "':\n" &
                e.msg.indent(2) & "\n"
        raise
  raise newException(EncodingError,
        &"Unknown branch name '" & branch_name & "', " &
        &"expected one of: {dd.branch_names}\n")

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
      continue
  raise newException(EncodingError,
          "Value invalid for all possible formats:\n" &
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

