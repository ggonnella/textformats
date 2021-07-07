import json, strformat, options, sets
import yaml/dom
import ../support/yaml_support
import ../types / [datatype_definition, match_element, def_syntax,
                   textformats_error]
import ../shared / [scalar_def_parser, matchelement_def_parser,
                    null_value_def_parser, encoded_def_parser,
                    as_string_def_parser]

proc newEnumDatatypeDefinition*(defroot: YamlNode, name: string):
                                DatatypeDefinition
import ../def_parser

const
  DefKey = EnumDefKey
  SyntaxHelp = &"""
  == (1) ==
  # list of int, float or string values:
  <datatype_name>:
    {DefKey}: [<x1>, <x2>, <x3>, ...]
  [optional_keys]

  == (2) ==
  # list of single-element mappings
  # to map the constants to a different elements;
  # keys must be int, float or string values
  <datatype_name>:
    - <x1>: <y1>
    - <x2>: <y2>
    ...
  # if multiple x values map to the same y
  # value, key '{EncodedKey}' must be included
  # specifying which x to use for encoding:
  {Encoded_Key}:
    <selected_x>: <duplicated_y>
    ...
  [optional_keys]

  Optional keys for decoding:
  - {NullValueKey}: {NullValueHelp}
  - {AsStringKey}: {AsStringHelp}
"""
  InvalidElemMsg = &"Invalid element in YAML sequence in '{DefKey}' node\n"

proc parse_elements(n: YamlNode): seq[MatchElement] =
  var previous = HashSet[string]()
  result = newseq[Matchelement]()
  n.validate_is_sequence()
  n.validate_min_len(2)
  for item in n.elems:
    let me = item.to_value_match_element(InvalidElemMsg)
    if $me in previous:
      raise newException(DefSyntaxError,
               &"Element is repeated\nRepeated element: {me}")
    previous.incl($me)
    result.add(me)

proc parse_decoded(n: YamlNode): seq[Option[JsonNode]] =
  assert n.kind == ySequence # already validated by parse_elements
  result = newseq_of_cap[Option[JsonNode]](n.len)
  for item in n.elems:
    result.add(item.to_decoded_value(InvalidElemMsg))

proc compute_encoded_map_validation_info(elements: seq[MatchElement],
                                        decoded: seq[Option[JsonNode]]):
                                        ValidationInfo =
  result = newValidationInfo()
  for i in 0 ..< elements.len:
    let opt_d = decoded[i]
    if opt_d.is_some:
      let dstr = $opt_d.unsafe_get
      result.add(dstr, elements[i])
  result.rm_singletons

proc newEnumDatatypeDefinition*(defroot: YamlNode, name: string):
                                DatatypeDefinition {.noinit.} =
  try:
    let defnodes = collect_defnodes(defroot,
                                    @[DefKey, NullValueKey, EncodedKey,
                                      AsStringKey])
    result = DatatypeDefinition(kind: ddkEnum, name: name,
        elements:   defnodes[0].unsafe_get.parse_elements,
        decoded:    defnodes[0].unsafe_get.parse_decoded,
        null_value: defnodes[1].parse_null_value,
        as_string:  defnodes[3].parse_as_string)
    let
      info = compute_encoded_map_validation_info(result.elements,
                                                 result.decoded)
      avoid_warning_tmp = defnodes[2].parse_encoded(info)
    result.encoded = avoid_warning_tmp
  except YamlSupportError, DefSyntaxError:
    reraise_as_def_syntax_error(name, SyntaxHelp, DefKey)
