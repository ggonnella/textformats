import strformat, json
import yaml
import ../support/yaml_support
import ../types / [def_syntax, textformats_error]

const
  ImplicitHelp* = "mapping: strings (key names) to scalar values"

proc parse_implicit*(optnode: OptYamlNode): seq[(string, JsonNode)] =
  result = newseq[(string, JsonNode)]()
  if optnode.is_some:
    let node = optnode.unsafe_get
    try:
      node.validate_is_mapping(
                  emsg_pfx = &"Invalid value for '{ImplicitKey}' key.\n")
      for key_node, value_node in node:
        key_node.validate_is_scalar(
                emsg_pfx = &"Invalid key in '{ImplicitKey}' list element.\n")
        try:
          result.add((key_node.to_string, value_node.to_json_node))
        except YamlSupportError:
          raise newException(YamlSupportError,
            &"Invalid value in '{ImplicitKey}' list element.\n" &
            get_current_exception_msg())
    except YamlSupportError:
      raise newException(DefSyntaxError,
                &"Invalid content of '{ImplicitKey}' key.\n" &
                &"Value: '{node.content}'\n" &
                get_current_exception_msg())

