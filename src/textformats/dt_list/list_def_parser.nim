import options
import strformat
import yaml/dom
import ../types / [datatype_definition, def_syntax, textformats_error]
import ../support / [error_support, yaml_support, openrange]
import ../shared / [formatting_def_parser, null_value_def_parser,
                    as_string_def_parser, scope_def_parser]

proc newListDatatypeDefinition*(defroot: YamlNode, name: string):
                                DatatypeDefinition
import ../def_parser

const
  DefKey = ListDefKey
  ListItemDefNameSfx = ".item"
  LenrangeMinHelp = "minimum number of elements in list (default: 1)"
  LenrangeMaxHelp = "maximum number of elements in list (default: unlimited)"
  LenHelp = "fixed number of elements in list " &
            &"(not compatible with {LenrangeMinKey} and {LenrangeMaxKey})"
  SyntaxHelp = &"""
  <datatype_name>:
    {DefKey}: <ref_or_def>
    [optional_keys]

  where <ref_or_def> is either:
  - a datatype name (string)
  - a datatype definition (mapping)

  Optional keys for validation:
  - {LenrangeMinKey}: {LenrangeMinHelp}
  - {LenrangeMaxKey}: {LenrangeMaxHelp}
  - {LenKey}: {LenHelp}

  Optional keys for formatting:
  - {PfxKey}: {PfxHelp}
  - {SfxKey}: {SfxHelp}
  - {SepKey}: {SepHelp}
  - {SplittedKey}: {SplittedHelp}

  Optional keys for decoding:
  - {NullValueKey}: {NullValueHelp}
  - {AsStringKey}: {AsStringHelp}
  - {ScopeKey}: {ScopeHelp}
  - {UnitsizeKey}: {UnitsizeHelp}
"""

proc parse_lenrange_min(minlength_optnode: Option[YamlNode]): Option[Natural] =
  try:
    result = minlength_optnode.to_opt_natural
    if result.is_none:
      result = some(1.Natural)
    elif result.unsafe_get == 0:
      result = none(Natural)
  except NodeValueError:
    reraise_prepend(&"Invalid value for '{LenrangeMinKey}'.\n")

proc parse_lenrange_max(maxlength_optnode: Option[YamlNode]): Option[Natural] =
  try:
    result = maxlength_optnode.to_opt_natural
  except NodeValueError:
    reraise_prepend(&"Invalid value for '{LenrangeMaxKey}'\n")

proc parse_members_def(of_node: YamlNode, name: string):
                       DatatypeDefinition {.noinit.} =
  try:
    result = newDatatypeDefinition(of_node, name)
  except:
    reraise_prepend(&"Invalid value for '{DefKey}'.\n" &
                     "Invalid list member datatype definition.\n")

proc newListDatatypeDefinition*(defroot: YamlNode, name: string):
                                DatatypeDefinition {.noinit.} =
  try:
    let defnodes = collect_defnodes(defroot, [DefKey, NullValueKey,
                                              LenrangeMinKey, LenrangeMaxKey,
                                              SepKey, PfxKey, SfxKey,
                                              SplittedKey, AsStringKey, LenKey,
                                              ScopeKey, UnitsizeKey])
    result = DatatypeDefinition(kind: ddkList, name: name,
        members_def: defnodes[0].unsafe_get.parse_members_def(
                       name & ListItemDefNameSfx),
        null_value:  defnodes[1].parse_null_value,
        pfx:         defnodes[5].parse_pfx,
        sfx:         defnodes[6].parse_sfx,
        as_string:   defnodes[8].parse_as_string,
        scope:       defnodes[10].parse_scope,
        unitsize:    defnodes[11].parse_unitsize)
    let (sep, sep_excl) = parse_sep(defnodes[4], defnodes[7])
    result.sep = sep
    result.sep_excl = sep_excl
    if defnodes[9].is_some:
      if defnodes[2].is_some:
        raise newException(DefSyntaxError,
                &"Key '{LenKey}' is incompatible with '{LenrangeMinKey}'\n")
      if defnodes[3].is_some:
        raise newException(DefSyntaxError,
                &"Key '{LenKey}' is incompatible with '{LenrangeMaxKey}'\n")
      result.lenrange.low = defnodes[9].parse_lenrange_min
      result.lenrange.high = defnodes[9].parse_lenrange_max
    else:
      result.lenrange.low = defnodes[2].parse_lenrange_min
      result.lenrange.high = defnodes[3].parse_lenrange_max
    result.lenrange.validate
  except YamlSupportError, DefSyntaxError, ValueError:
    reraise_as_def_syntax_error(name, SyntaxHelp, DefKey)
