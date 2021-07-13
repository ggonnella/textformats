import json
import options
import ../types/datatype_definition
import ../support/json_support
import ../types/match_element

template enum_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool =
  result = false
  if item.is_scalar:
    if dd.encoded.is_some and item in dd.encoded.unsafe_get:
      result = true
    else:
      for i, me in dd.elements:
        if dd.decoded[i].is_none:
          let found =
            case me.kind:
            of meFloat:  item.is_float  and item.get_float == me.f_value
            of meInt:    item.is_int    and item.get_biggest_int == me.i_value
            of meString: item.is_string and item.get_str == me.s_value
          if found:
            result = true
            break
        elif dd.decoded[i].unsafe_get == item:
          result = true
          break
  result
