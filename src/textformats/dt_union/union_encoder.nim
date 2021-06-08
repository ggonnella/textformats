import json, strformat, strutils
import ../types / [datatype_definition, textformats_error]
import ../encoder

proc union_encode*(value: JsonNode, dd: DatatypeDefinition): string =
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
  for c in dd.choices:
    try: return value.unsafe_encode(c)
    except ValueError: continue
  assert(false)

