import options, strformat
import yaml/dom
import ../types / [datatype_definition, def_syntax, textformats_error]
import ../support/yaml_support
import ../shared / [minmaxexcluded_def_parser, null_value_def_parser,
                    as_string_def_parser]

proc newFloatRangeDatatypeDefinition*(defroot: YamlNode, name: string):
                                      DatatypeDefinition
import ../def_parser

const
  DefKey = FloatRangeDefKey
  SyntaxHelp = &"""
  <datatype_name>:
    {DefKey}:
      {MinKey}: <float>
      {MinExcludedKey}: <bool>
      {MaxKey}: <float>
      {MaxExcludedKey}: <bool>
    [optional_keys]

  All keys under {DefKey} are optional.
  The default is:
  - {MinKey} is -Infinite
  - {MinKey} is included (is a valid value)
  - {MaxKey} is Infinite
  - {MaxKey} is included (is a valid value)

  Optional keys:
  - {NullValueKey}: {NullValueHelp}
  - {AsStringKey}: {AsStringHelp}
"""

proc parse_min_f(min_optnode: Option[YamlNode]): float =
  try:
    let value = min_optnode.to_opt_float
    return if value.is_none: NegInf else: value.unsafe_get
  except NodeValueError:
    raise newException(DefSyntaxError,
            &"Invalid value for '{MinKey}' ({min_optnode})")

proc parse_max_f(max_optnode: Option[YamlNode]): float =
  try:
    let value = max_optnode.to_opt_float
    return if value.is_none: Inf else: value.unsafe_get
  except NodeValueError:
    raise newException(DefSyntaxError,
            &"Invalid value for '{MaxKey}' ({max_optnode})")

proc validate_float_range(min_f: float, max_f: float) =
  if min_f > max_f:
    raise newException(DefSyntaxError,
            &"Invalid range definition: min > max\n" &
            &"Specified minimum: {min_f}\n" &
            &"Specified maximum: {max_f}")

proc newFloatRangeDatatypeDefinition*(defroot: YamlNode, name: string):
                                      DatatypeDefinition {.noinit.} =
  try:
    let
      defnodes = collect_defnodes(defroot, [DefKey, NullValueKey, AsStringKey])
      subdefnodes = collect_defnodes(defnodes[0].unsafe_get,
                              [MinKey, MaxKey, MinExcludedKey, MaxExcludedKey],
                              n_required = 0)
    result = DatatypeDefinition(kind: ddkFloatRange, name: name,
                           min_f: subdefnodes[0].parse_min_f,
                           max_f: subdefnodes[1].parse_max_f,
                           minincl: not subdefnodes[2].parse_minexcluded,
                           maxincl: not subdefnodes[3].parse_maxexcluded,
                           null_value: defnodes[1].parse_null_value,
                           as_string: defnodes[2].parse_as_string)
    validate_requires(MinExcludedKey, subdefnodes[2], MinKey, subdefnodes[0])
    validate_requires(MaxExcludedKey, subdefnodes[3], MaxKey, subdefnodes[1])
    validate_float_range(result.min_f, result.max_f)
  except YamlSupportError, DefSyntaxError:
    reraise_as_def_syntax_error(name, SyntaxHelp, DefKey)

