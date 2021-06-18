import options
import strformat
import yaml/dom
import ../types / [datatype_definition, def_syntax, textformats_error]
import ../support / [yaml_support, error_support]
import ../shared / [null_value_def_parser, as_string_def_parser]

proc newUnionDatatypeDefinition*(defroot: YamlNode, name: string):
                                 DatatypeDefinition
import ../def_parser

const
  DefKey = UnionDefKey
  SyntaxHelp = &"""
  <datatype_name>:
    {DefKey}:
      - <x1>
      - <x2>
  [optional keys]

  where:
  - <xN> is either:
    - a datatype name (string); or
    - a datatype definition (map)

  Optional keys:
  - {NullValueKey}: {NullValueHelp}
  - {AsStringKey}: {AsStringHelp}
  """

proc parse_choices(defnode: YamlNode, name: string): seq[DatatypeDefinition] =
  defnode.validate_is_sequence(&"Invalid value of '{DefKey}' node.\n")
  defnode.validate_min_len(2, &"Invalid content of 'DefKey' node.\n")
  var i = 0
  for node in defnode.elems:
    try:
      let choice_name =
        if node.kind == yScalar: name & "." & node.to_string
        else:                    name & &"[{i}]"
      result.add(newDatatypeDefinition(node, choice_name))
    except YamlSupportError:
      reraise_prepend(&"Invalid element in '{DefKey}' key.\n")
    i += 1

proc newUnionDatatypeDefinition*(defroot: YamlNode, name: string):
                                 DatatypeDefinition {.noinit.} =
  try:
    var defnodes = collect_defnodes(defroot, [DefKey,
                      NullValueKey, AsStringKey])
    result = DatatypeDefinition(kind: ddkUnion, name: name,
        choices:    defnodes[0].unsafe_get.parse_choices(name),
        null_value: defnodes[1].parse_null_value,
        as_string:  defnodes[2].parse_as_string)
  except YamlSupportError, DefSyntaxError:
    reraise_as_def_syntax_error(name, SyntaxHelp, DefKey)
