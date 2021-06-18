import options
import yaml/dom
import ../support/yaml_support
import ../types/def_syntax

const
  AsStringHelp* = "use definition for validation only, "&
                  "decoded value is encoded string (default: false)"

proc parse_as_string*(node: Option[YamlNode]): bool =
  return node.to_bool(default=false, AsStringKey)
