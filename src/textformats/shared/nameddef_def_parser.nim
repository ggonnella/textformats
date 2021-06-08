import yaml
import tables
import ../support/error_support
export error_support
import ../types/datatype_definition

const DatatypeDefinitionNameSep* = "."
template subdef_name*(name: string, subdefkey: string): string =
  name & DatatypeDefinitionNameSep & subdefkey

template parse_named_definitions_to_seq*(defnode: YamlNode, name: string,
                                         defkey: string):
                                           seq[(string, DatatypeDefinition)] =
  var outvar = newseq[(string, DatatypeDefinition)]()
  try:
    defnode.validate_is_sequence("Invalid value for '" & defkey & "'.\n")
    defnode.validate_min_len(1,
                "Invalid number of elements of '" & defkey & "'.\n")
    for element in defnode:
      element.validate_is_mapping("Invalid value in '" & defkey & "' list.\n")
      element.validate_len(1, "Invalid value in '" & defkey & "' list.\n")
      for key_node, value_node in element:
        key_node.validate_is_scalar(
                "Invalid key in '" & defkey & "' list element.\n")
        try:
          let
            key_str = key_node.to_string
            elem_def = newDatatypeDefinition(value_node,
                                             subdefname(name, key_str))
          outvar.add((key_str, elem_def))
        except YamlSupportError:
          reraise_prepend("Invalid value in '" & defkey & "' list element.\n")
  except YamlSupportError:
    reraise_prepend("Invalid value for '" & defkey & "'.\n" &
                    "Value: '" & $defnode & "'\n")
  outvar

template parse_named_definitions_to_table*(defnode: YamlNode, name: string,
           defkey: string):
                             TableRef[string, DatatypeDefinition] =
  var outvar = newTable[string, DatatypeDefinition]()
  try:
    defnode.validate_is_mapping("Invalid value for '" & defkey & "'.\n")
    defnode.validate_min_len(1,
                "Invalid number of elements of '" & defkey & "'.\n")
    for key_node, value_node in defnode:
      key_node.validate_is_scalar(
              "Invalid key in '" & defkey & "' list element.\n")
      try:
        let
          key_str = key_node.to_string
          elem_def = newDatatypeDefinition(value_node,
                                           subdefname(name, key_str))
        outvar[key_str] = elem_def
      except YamlSupportError:
        reraise_prepend(
          "Invalid value in '" & defkey & "' list element.\n")
  except YamlSupportError:
    reraise_prepend("Invalid value for '" & defkey & "'.\n" &
                    "Value: '" & $defnode & "'\n")
  outvar
