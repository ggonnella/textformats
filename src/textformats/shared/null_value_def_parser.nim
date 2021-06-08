import options, json, strformat
import yaml/dom
import ../support / [yaml_support, error_support]
import ../types/def_syntax

const
  NullValueHelp* = "decoded value for empty encoded string "&
                   "(default: no special case)"

proc parse_null_value*(optnode: Option[YamlNode]): Option[JsonNode] =
  try:
    result = optnode.to_opt_json_node
  except NodeValueError:
    reraise_prepend(&"Invalid value for '{NullValueKey}'.\n")
