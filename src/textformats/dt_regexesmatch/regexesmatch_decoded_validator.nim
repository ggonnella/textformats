import json
import options
import regex
import ../types/datatype_definition
import ../support/json_support

template regexesmatch_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool =
  result = false
  if item.is_scalar:
    if dd.encoded.is_some and item in dd.encoded.unsafe_get:
      result = true
    else:
      for i, r in dd.regexes_compiled:
        if dd.decoded[i].is_none:
          if item.is_string and item.get_str.match(r):
            result = true
            break
        elif dd.decoded[i].unsafe_get == item:
          result = true
          break
  result
