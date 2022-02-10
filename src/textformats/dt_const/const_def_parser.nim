import json
import strformat
import options
import yaml/dom
import ../support/yaml_support
import ../types / [datatype_definition, match_element, def_syntax,
                   textformats_error]
import ../shared / [matchelement_def_parser, scalar_def_parser,
                    null_value_def_parser, as_string_def_parser]

proc newConstDatatypeDefinition*(defroot: YamlNode, name: string):
                                 DatatypeDefinition
import ../def_parser

const
  DefKey = ConstDefKey
  SyntaxHelp = &"""
  == 1 ==
  <datatype_name>:
    {DefKey}: <str_or_num>

  == 2 ==
  <datatype_name>:
    {DefKey}: {{<str_or_num>: <value>}}

  == 3 ==
  <datatype_name>:
    {DefKey}: {{<str_or_num>: <value>, {NullValueKey}: <value>}}

  where:
    <str_or_num> is a string, integer or float
    <value> is a scalar or compound value

  Optional keys for decoding:
  - {NullValueKey}: {NullValueHelp}
  - {AsStringKey}: {AsStringHelp}
  """

proc parse_constant_element(n: YamlNode): MatchElement =
  let errmsg = &"Invalid constant value: {n.to_json_node}"
  n.to_value_match_element(errmsg)

proc parse_decoded(n: YamlNode): seq[Option[JsonNode]] =
  let errmsg = &"Invalid decoding map value: {n.to_json_node}"
  result = newseq[Option[JsonNode]](1)
  result[0]=n.to_decoded_value(errmsg)

proc newConstDatatypeDefinition*(defroot: YamlNode, name: string):
                                DatatypeDefinition {.noinit.} =
  var errmsg = ""
  try:
    let defnodes = collect_defnodes(defroot, @[DefKey, NullValueKey,
                                               AsStringKey])
    result = DatatypeDefinition(kind: ddkConst, name: name,
        constant_element: defnodes[0].unsafe_get.parse_constant_element,
        decoded:          defnodes[0].unsafe_get.parse_decoded,
        null_value:       defnodes[1].parse_null_value,
        as_string:        defnodes[2].parse_as_string)
  except YamlSupportError, DefSyntaxError:
    errmsg = getCurrentException().msg
  raise_if_had_error(errmsg, name, SyntaxHelp, DefKey)
