import tables
import options
import yaml/dom
import ../support/yaml_support
import ../types/match_element

proc scalar_node_to_value_match_element(n: YamlNode): MatchElement =
  if n.is_int():     MatchElement(kind: meInt, i_value: n.to_int)
  elif n.is_float(): MatchElement(kind: meFloat,  f_value: n.to_float)
  else:              MatchElement(kind: meString, s_value: n.to_string)

proc mapping_node_to_value_match_element(n: YamlNode, errmsg: string):
                                         MatchElement =
  n.validate_len(1, errmsg)
  for k, v in n:
    k.validate_is_scalar(errmsg)
    result = k.scalar_node_to_value_match_element

proc to_value_match_element*(n: YamlNode, errmsg: string): MatchElement =
  case n.kind:
    of yScalar:    # a single value (integer, float or string)
      result = n.scalar_node_to_value_match_element
    of yMapping:   # value => scalar map
      result = n.mapping_node_to_value_match_element(errmsg)
    of ySequence:  # error
      raise newException(NodeValueError, errmsg)

