import json
import ../support/json_support
import ../types/match_element

proc encode_match_elem_with_decoded*(value: JsonNode, decoded: JsonNode,
                                    me: MatchElement, encoded: var string):
                                    bool {.inline.} =
  if decoded == value:
    case me.kind:
    of meFloat:  encoded = $me.f_value
    of meInt:    encoded = $me.i_value
    of meString:
      encoded = me.s_value
    return true
  else:
    return false

proc encode_match_elem_wo_decoded*(value: JsonNode, me: MatchElement,
                                  encoded: var string): bool {.inline.} =
  case me.kind:
  of meFloat:
    if value.is_float and value.get_float == me.f_value:
      encoded = $value.get_float
      return true
  of meInt:
    if value.is_int and value.get_biggest_int == me.i_value:
      encoded = $value.get_biggest_int
      return true
  of meString:
    if value.is_string and value.get_str == me.s_value:
      encoded = $value.get_str
      return true
  return false
