import options
import strformat
import yaml/dom
import ../types / [datatype_definition, def_syntax, textformats_error]
import ../support / [yaml_support, error_support, openrange]
import ../shared / [minmaxexcluded_def_parser, null_value_def_parser,
                    as_string_def_parser]

proc newUintRangeDatatypeDefinition*(defroot: YamlNode, name: string):
                                     DatatypeDefinition
import ../def_parser

const
  DefKey = UintRangeDefKey
  SyntaxHelp = &"""
  <datatype_name>:
    {DefKey}:
      {MinKey}: <unsigned_integer>
      {MaxKey}: <unsigned_integer>
      {BaseKey}: 2, 8, 10 or 16
    [optional_keys]

  All keys under {DefKey} are optional.

  Optional keys for text representation format:
  - {BaseKey}: integer base to use, default: 10

  Optional keys for decoded value validation:
  - {MinKey}: minimum value, default 0
  - {MaxKey}: maximum value, default: highest int value (*)
  (*) of largest available _signed_ int type

  Optional keys for decoding:
  - {NullValueKey}: {NullValueHelp}
  - {AsStringKey}: {AsStringHelp}
"""

proc parse_range_u(min_max_optnodes: tuple[min: OptYamlNode,
                     max: OptYamlNode]): Openrange[uint64] =
  try:
    result.low = min_max_optnodes.min.to_opt_uint
  except NodeValueError:
    reraise_prepend(
      &"Invalid value for '{MinKey}' ({min_max_optnodes.min}).\n")
  try:
    result.high = min_max_optnodes.max.to_opt_uint
  except NodeValueError:
    reraise_prepend(
      &"Invalid value for '{MaxKey}' ({min_max_optnodes.max}).\n")

proc parse_base(n: OptYamlNode): int =
  if n.is_none:
    return 10
  else:
    let nsome = n.unsafe_get
    if nsome.is_int:
      let b = nsome.to_int
      if b == 2 or b == 8 or b == 10 or b == 16:
        return b.int
    raise newException(DefSyntaxError,
      &"The value of '{BaseKey}' must be one of (integer): 2, 8, 10, 16.\n")

proc newUintRangeDatatypeDefinition*(defroot: YamlNode, name: string):
                                     DatatypeDefinition {.noinit.} =
  var errmsg = ""
  try:
    let
      defnodes = collect_defnodes(defroot, [DefKey, NullValueKey, AsStringKey])
      subdefnodes = collect_defnodes(defnodes[0].unsafe_get,
                      [MinKey, MaxKey, MinExcludedKey, MaxExcludedKey, BaseKey],
                      n_required = 0)
    result = DatatypeDefinition(kind: ddkUIntRange, name: name,
               range_u: (subdefnodes[0], subdefnodes[1]).parse_range_u,
               null_value: defnodes[1].parse_null_value,
               as_string: defnodes[2].parse_as_string,
               base: subdefnodes[4].parse_base)
    validate_requires(MinExcludedKey, subdefnodes[2], MinKey, subdefnodes[0])
    validate_requires(MaxExcludedKey, subdefnodes[3], MaxKey, subdefnodes[1])
    if subdefnodes[2].parse_minexcluded:
      result.range_u.safe_inc_min
    if subdefnodes[3].parse_maxexcluded:
      result.range_u.safe_dec_max
    result.range_u.validate
  except YamlSupportError, DefSyntaxError, ValueError:
    errmsg = getCurrentException().msg
  raise_if_had_error(errmsg, name, SyntaxHelp, DefKey)
