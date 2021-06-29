import json, strformat, options
import yaml/dom
import ../support/yaml_support
import ../types / [datatype_definition, def_syntax, textformats_error]
import ../shared / [scalar_def_parser, null_value_def_parser,
                    encoded_def_parser, rmatch_def_parser]

proc newRegexesMatchDatatypeDefinition*(defroot: YamlNode, name: string):
                                        DatatypeDefinition
import ../def_parser

const
  Defkey = RegexesMatchDefKey
  SyntaxHelp = &"""
  # (1) list of regular expressions (strings)
    <datatype_name>:
      {DefKey}: [<regex1>, <regex2>]
      [optional_keys]

  # (2) list including decoded values
    <datatype_name>:
      {DefKey}:
        - <list_elem1>
        - <list_elem2>
        ...
      {EncodedKey}: {{<scalar>: <string>}}
      [optional_keys]

    where each <list_elem> is either
    - a string: regular expression; or
    - a mapping string => scalar value:
        regular expression to decoded value to use when matching

    A mapping must be included under {EncodedKey},
    where keys are all scalar values used under {DefKey}.

  Optional keys for decoding:
  - {NullValueKey}: {NullValueHelp}
  """

proc parse_regexes_raw(n: YamlNode): seq[string] =
  const
    errmsg_whole = &"Invalid content of '{DefKey}' node\n"
    errmsg_elem  = &"Invalid element in '{DefKey}' list\n"
  result = newseq[string]()
  n.validate_is_sequence(errmsg_whole)
  n.validate_min_len(2, errmsg_whole)
  for item in n.elems:
    result.add(item.to_regex_raw(errmsg_elem))

proc parse_regexes_decoded(n: YamlNode): seq[Option[JsonNode]] =
  const errmsg_elem = &"Invalid element in '{DefKey}' list\n"
  assert n.kind == ySequence # already validated by parse_regexes_raw
  result = newseq_of_cap[Option[JsonNode]](n.len)
  for item in n.elems:
    result.add(item.to_decoded_value(errmsg_elem))

proc compute_encoded_map_validation_info(rrs: seq[string],
                                         decoded: seq[Option[JsonNode]]):
                                         ValidationInfo =
  result = newValidationInfo()
  for i in 0 ..< rrs.len:
    let opt_d = decoded[i]
    if opt_d.is_some:
      let dstr = $opt_d.unsafe_get
      result.add(dstr, rrs[i])

proc newRegexesMatchDatatypeDefinition*(defroot: YamlNode, name: string):
                                        DatatypeDefinition {.noinit.} =
  try:
    let defnodes = collect_defnodes(defroot, @[DefKey,
                                    EncodedKey, NullValueKey])
    result = DatatypeDefinition(kind: ddkRegexesMatch, name: name,
        regexes_raw: defnodes[0].unsafe_get.parse_regexes_raw,
        decoded:     defnodes[0].unsafe_get.parse_regexes_decoded,
        null_value:  defnodes[2].parse_null_value)
    let
      info = compute_encoded_map_validation_info(result.regexes_raw,
                                                 result.decoded)
      avoid_warning_tmp = defnodes[1].parse_encoded(info)
    result.encoded = avoid_warning_tmp
  except YamlSupportError, DefSyntaxError:
    reraise_as_def_syntax_error(name, SyntaxHelp, DefKey)

