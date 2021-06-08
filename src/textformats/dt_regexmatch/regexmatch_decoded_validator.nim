import json
import options
import regex
import ../types/datatype_definition
import ../support/json_support

template regexmatch_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool =
  result = false
  if item.is_scalar:
    if dd.encoded.is_some and
      item in dd.encoded.unsafe_get:
        result = true
    elif dd.decoded[0].is_none:
      result = item.is_string and item.get_str.match(dd.regex.compiled)
    else:
      result = dd.decoded[0].unsafe_get == item
  result
