import json, strformat, options
import yaml/dom
import ../support/yaml_support
import ../types / [datatype_definition, def_syntax, textformats_error]
import ../shared / [scalar_def_parser, null_value_def_parser,
                    encoded_def_parser, rmatch_def_parser]

proc newRegexMatchDatatypeDefinition*(defroot: YamlNode, name: string):
                                      DatatypeDefinition
import ../def_parser

const
  DefKey = RegexMatchDefKey
  SyntaxHelp = &"""
  # regular expression (string)
  <datatype_name>:
    {DefKey}: <string>
    [optional_keys]

  # map of regular expression (string)
  # to scalar value (string, numeric, bool, none)
  # and reverse map of the same scalar value
  # to a string matching the regular expression
  <datatype_name>:
    {DefKey}: {{<string>: <scalar>}}
    {EncodedKey}: {{<scalar>: <string>}}
    [optional_keys]

  Optional keys:
    {NullValueKey}: {NullValueHelp}
"""
  InvalidContentMsg = &"Invalid content of key '{DefKey}':\n"

proc parse_decoded(n: YamlNode): seq[Option[JsonNode]] =
  result = newseq[Option[JsonNode]](1)
  result[0] = n.to_decoded_value(InvalidContentMsg)

proc compute_encoded_map_validation_info(rr: string,
                                         opt_d: Option[JsonNode]):
                                         ValidationInfo =
  result = newValidationInfo()
  if opt_d.is_some:
    result.add($opt_d.unsafe_get, rr)

proc newRegexMatchDatatypeDefinition*(defroot: YamlNode, name: string):
                                      DatatypeDefinition {.noinit.} =
  try:
    let defnodes =
      collect_defnodes(defroot, @[DefKey, EncodedKey, NullValueKey])
    result = DatatypeDefinition(kind: ddkRegexMatch, name: name,
        decoded:    defnodes[0].unsafe_get.parse_decoded,
        null_value: defnodes[2].parse_null_value)
    result.regex.raw = defnodes[0].unsafe_get.to_regex_raw(InvalidContentMsg)
    let
      info = compute_encoded_map_validation_info(result.regex.raw,
                                                 result.decoded[0])
      avoid_warning_tmp = defnodes[1].parse_encoded(info)
    result.encoded = avoid_warning_tmp
  except YamlSupportError, DefSyntaxError:
    reraise_as_def_syntax_error(name, SyntaxHelp, DefKey)
