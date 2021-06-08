import json
import options
import ../types/datatype_definition
import ../support/json_support
import ../types/match_element

template const_is_valid*(item: JsonNode, dd: DatatypeDefinition): bool =
  result = false
  if item.is_scalar:
    if dd.decoded[0].is_none:
      case dd.constant_element.kind:
      of meFloat:
        result = item.is_float and item.get_float == dd.constant_element.f_value
      of meInt:
        result = item.is_int and item.get_int == dd.constant_element.i_value
      of meString:
        result = item.is_string and item.get_str == dd.constant_element.s_value
    else:
      result = dd.decoded[0].unsafe_get == item
  result

