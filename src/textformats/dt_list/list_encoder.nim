import json, sequtils, strutils, strformat
import ../types / [datatype_definition, textformats_error]
import ../support / [json_support, openrange]
import ../encoder

proc list_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_array:
    raise newException(EncodingError, "Error: value is not an array\n" &
                       value.describe_kind & "\n")
  if value.len notin dd.lenrange:
    raise newException(EncodingError, "Error: list length is invalid\n" &
                       &"Minimum valid list length: {dd.lenrange.low}\n" &
                       &"Maximum valid list length: {dd.lenrange.high}\n" &
                       &"Found list length: {value.len}\n")
  result = dd.pfx
  var i = 0
  for item in value:
    var encoded: string
    try:
      encoded = item.encode(dd.members_def)
    except EncodingError:
      raise newException(EncodingError, "Error: list item is invalid\n" &
                      &"N. of valid items before invalid one: {i}\n" &
                      "Error of encoding invalid item:\n" &
                      get_current_exception_msg().indent(2))
    if i > 0: result &= dd.sep
    result &= encoded
    i += 1
  result &= dd.sfx

proc list_unsafe_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  return dd.pfx & value.get_elems.map_it(
           it.unsafe_encode(dd.members_def)).join(dd.sep) & dd.sfx
