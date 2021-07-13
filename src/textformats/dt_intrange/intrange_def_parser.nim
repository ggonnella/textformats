import options
import strformat
import yaml/dom
import ../types / [datatype_definition, def_syntax, textformats_error]
import ../support / [yaml_support, openrange]
import ../shared / [minmaxexcluded_def_parser, null_value_def_parser,
                    as_string_def_parser]

proc newIntrangeDatatypeDefinition*(defroot: YamlNode, name: string):
                                    DatatypeDefinition
import ../def_parser

const
  DefKey = IntRangeDefKey
  SyntaxHelp = &"""
  <datatype_name>:
    {DefKey}:
      {MinKey}: <integer>
      {MaxKey}: <integer>
    [optional_keys]

  All keys under {DefKey} are optional.

  Optional keys for decoded value validation:
  - {MinKey}: minimum value, default: lowest int value (*)
  - {MaxKey}: maximum value, default: highest int value (*)
  (*) of largest available signed int type

  Optional keys for decoding:
  - {NullValueKey}: {NullValueHelp}
  - {AsStringKey}: {AsStringHelp}
"""

proc parse_range_i(min_max_optnodes:
                   tuple[min: Option[YamlNode], max: Option[YamlNode]]):
                   Openrange[int64] =
  try:
    result.rmin = min_max_optnodes.min.to_opt_int
  except NodeValueError:
    raise newException(DefSyntaxError,
      &"Invalid value for '{MinKey}' ({min_max_optnodes.min}).\n" &
      get_current_exception_msg())
  try:
    result.rmax = min_max_optnodes.max.to_opt_int
  except NodeValueError:
    raise newException(DefSyntaxError,
      &"Invalid value for '{MaxKey}' ({min_max_optnodes.max}).\n" &
      get_current_exception_msg())

proc newIntrangeDatatypeDefinition*(defroot: YamlNode, name: string):
                                    DatatypeDefinition {.noinit.} =
  try:
    let
      defnodes = collect_defnodes(defroot, [DefKey, NullValueKey, AsStringKey],
                                  n_required = 1)
      subdefnodes = collect_defnodes(defnodes[0].unsafe_get,
                      [MinKey, MaxKey, MinExcludedKey, MaxExcludedKey],
                      n_required = 0)
    result = DatatypeDefinition(kind: ddkIntRange, name: name,
               range_i: (subdefnodes[0], subdefnodes[1]).parse_range_i,
               null_value: defnodes[1].parse_null_value,
               as_string: defnodes[2].parse_as_string)
    validate_requires(MinExcludedKey, subdefnodes[2], MinKey, subdefnodes[0])
    validate_requires(MaxExcludedKey, subdefnodes[3], MaxKey, subdefnodes[1])
    if subdefnodes[2].parse_minexcluded:
      result.range_i.safe_inc_min
    if subdefnodes[3].parse_maxexcluded:
      result.range_i.safe_dec_max
    result.range_i.validate
  except YamlSupportError, DefSyntaxError, ValueError:
    reraise_as_def_syntax_error(name, SyntaxHelp, DefKey)

