import json, sequtils, strutils, strformat
import ../types / [datatype_definition, textformats_error]
import ../support / [json_support, openrange]
import ../encoder

proc list_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_array:
    raise newException(EncodingError, "Value is not an array, found: " &
                       value.describe_kind & "\n")
  if value.len notin dd.lenrange:
    raise newException(EncodingError, "List length {value.len} is not in " &
                       &"range {dd.lenrange.low}..{dd.lenrange.high}\n")
  result = dd.pfx
  var i = 0
  for item in value:
    var encoded: string
    try:
      encoded = item.encode(dd.members_def)
    except EncodingError:
      let e = get_current_exception()
      e.msg = &"Invalid list element after {i} valid elements:\n" &
              e.msg.indent(2)
      raise
    if i > 0: result &= dd.sep
    result &= encoded
    i += 1
  result &= dd.sfx

proc list_unsafe_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  return dd.pfx & value.get_elems.map_it(
           it.unsafe_encode(dd.members_def)).join(dd.sep) & dd.sfx
