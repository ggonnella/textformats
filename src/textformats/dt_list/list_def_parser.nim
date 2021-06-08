import options
import strformat
import yaml/dom
import ../types / [datatype_definition, def_syntax, textformats_error]
import ../support / [error_support, yaml_support, openrange]
import ../shared / [formatting_def_parser, null_value_def_parser]

proc newListDatatypeDefinition*(defroot: YamlNode, name: string):
                                DatatypeDefinition
import ../def_parser

const
  DefKey = ListDefKey
  ListItemDefNameSfx = ".item"
  LenrangeMinHelp = "minimum number of elements in list (default: 1)"
  LenrangeMaxHelp = "maximum number of elements in list (default: unlimited)"
  SyntaxHelp = &"""
  <datatype_name>:
    {DefKey}: <ref_or_def>
    [optional_keys]

  where <ref_or_def> is either:
  - a datatype name (YAML scalar node)
  - a datatype definition (YAML mapping node)

  Optional keys:
  - {LenrangeMinKey}: {LenrangeMinHelp}
  - {LenrangeMaxKey}: {LenrangeMaxHelp}
  - {NullValueKey}: {NullValueHelp}
  - {SepKey}: {SepHelp}
  - {SepExclKey}: {SepExclHelp}
  - {PfxKey}: {PfxHelp}
  - {SfxKey}: {SfxHelp}
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
                                              SepExclKey])
    result = DatatypeDefinition(kind: ddkList, name: name,
        members_def: defnodes[0].unsafe_get.parse_members_def(
                       name & ListItemDefNameSfx),
        null_value:  defnodes[1].parse_null_value,
        lenrange:   (defnodes[2].parse_lenrange_min,
                     defnodes[3].parse_lenrange_max),
        sep:         defnodes[4].parse_sep,
        pfx:         defnodes[5].parse_pfx,
        sfx:         defnodes[6].parse_sfx,
        sep_excl:    defnodes[7].parse_sep_excl)
    validate_sep_if_sepexcl(defnodes[7], defnodes[4])
    result.lenrange.validate
  except YamlSupportError, DefSyntaxError, ValueError:
    reraise_as_def_syntax_error(name, SyntaxHelp, DefKey)
