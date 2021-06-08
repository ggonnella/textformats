import options
import strformat
import yaml/dom
import ../support / [yaml_support, error_support]
import ../types/def_syntax

proc parse_minexcluded*(node: Option[YamlNode]): bool =
  try:
    result = node.to_bool(default=false)
  except NodeValueError:
    reraise_prepend(&"Invalid value for '{MinExcludedKey}'.\n")

proc parse_maxexcluded*(node: Option[YamlNode]): bool =
  try:
    result = node.to_bool(default=false)
  except NodeValueError:
    reraise_prepend(&"Invalid value for '{MaxExcludedKey}'.\n")

