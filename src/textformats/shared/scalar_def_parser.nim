import options, json
import yaml/dom
import ../support/yaml_support

proc to_decoded_value*(n: YamlNode, errmsg: string): Option[JsonNode] =
  case n.kind:
    of yScalar:    # a single value (integer, float or string)
      result = JsonNode.none
    of yMapping:   # value => Scalar map
      n.validate_len(1, errmsg)
      for k, v in n:
        v.validate_is_scalar(errmsg)
        result = v.to_json_node.some
    of ySequence:  # error
      raise newException(NodeValueError, errmsg)

