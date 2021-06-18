import strformat, sequtils, yaml, tables
import ../types / [datatype_definition, def_syntax, textformats_error]
import ../support/yaml_support
import ../shared / [formatting_def_parser, implicit_def_parser,
                    null_value_def_parser, nameddef_def_parser,
                    as_string_def_parser]

proc newDictDatatypeDefinition*(defroot: YamlNode, name: string):
                                DatatypeDefinition

import ../def_parser

const
  DefKey = DictDefKey
  DictRequiredHelp = "list of keys which are required to be present"
  DictInternalSepHelp* = "separator between key and value of each element " &
                         "(string, mandatory)"
  SingleHelp = "list of keys which are allowed to be present only once"

  SyntaxHelp = &"""
  <datatype_name>:
    {DefKey}:
      <x1>: <y1>
      <x2>: <y2>
      ...
    {SepKey}: ...
    {DictInternalSepKey}: ...
    [optional keys]

  where:
  - 'x<N>' is a key name (string)
  - 'y<N>' is either:
    - a datatype name (string); or
    - a datatype definition (map)
  - {SepKey}: {SepHelp}
  - {DictInternalSepKey}: {DictInternalSepHelp}
  - {SepKey} and {DictInternalSepKey} must be different, non-empty strings
    and {DictInternalSepKey} must not be contain {SepKey}

  Optional keys:
  - {DictRequiredKey}: {DictRequiredHelp}
  - {PfxKey}: {PfxHelp}
  - {SfxKey}: {SfxHelp}
  - {NullValueKey}: {NullValueHelp}
  - {ImplicitKey}: {ImplicitHelp}
  - {SingleKey}: {SingleHelp}
  - {AsStringKey}: {AsStringHelp}
  """

proc parse_dict_members(n: YamlNode, name: string):
                       TableRef[string, DatatypeDefinition] =
  result = n.parse_named_definitions_to_table(name, DefKey)
  if result.len == 0:
    raise newException(DefSyntaxError,
            &"No elements defined in '{DefKey}'\n")

proc parse_keys_list(opt_n: Option[YamlNode], key: string,
                         dict_members: TableRef[string, DatatypeDefinition]):
                           seq[string] =
  result = newseq[string]()
  let
    err_whole = &"Invalid value for '{key}'\n"
    err_item = &"Invalid value in '{key} list'\n"
  if opt_n.is_some:
    let n = opt_n.unsafe_get
    n.validate_is_sequence(err_whole)
    for i in n:
      i.validate_is_string(err_item & &"Invalid value: {i}\n")
      let istr = i.to_string
      if istr notin dict_members:
        raise newException(DefSyntaxError,
                err_item & &"Invalid value: {istr}\n" &
                &"Value is not one of the keys of '{DefKey}'\n" &
                &"Keys of '{DefKey}': {to_seq(dict_members.keys)}")
      result.add(i.to_string)

proc parse_dict_internal_sep*(node: Option[YamlNode]): string =
  node.to_string(default="", DictInternalSepKey)

proc validate_implicit(dd: DatatypeDefinition) =
  for implicit_member in dd.implicit:
    if implicit_member.name in dd.dict_members:
      raise newException(DefSyntaxError,
              "Implicit member name equal to a member name\n" &
              &"Duplicated name: {implicit_member.name}")

proc validate_names_vs_separators(dd: DatatypeDefinition) =
  let
    dm = to_seq(dd.dict_members.keys)
    dmlbl = "Member name"
    seplbl = "elements"
    iseplbl = "name/value"
  validate_names_vs_separator(dm, dmlbl, dd.sep, seplbl)
  validate_names_vs_separator(dm, dmlbl, dd.dict_internal_sep, iseplbl)

proc newDictDatatypeDefinition*(defroot: YamlNode, name: string):
                                DatatypeDefinition {.noinit.} =
  try:
    let defnodes = collect_defnodes(defroot,
                     [DefKey, SepKey, DictInternalSepKey, NullValueKey,
                     PfxKey, SfxKey, ImplicitKey, DictRequiredKey, SingleKey,
                     AsStringKey],
                     3)
    result = DatatypeDefinition(kind: ddkDict, name: name,
      dict_members:           defnodes[0].unsafe_get.parse_dict_members(name),
      sep:                    defnodes[1].parse_sep,
      dict_internal_sep:      defnodes[2].parse_dict_internal_sep,
      null_value:             defnodes[3].parse_null_value,
      pfx:                    defnodes[4].parse_pfx,
      sfx:                    defnodes[5].parse_sfx,
      implicit:               defnodes[6].parse_implicit,
      as_string:              defnodes[9].parse_as_string)
    result.required_keys =
      defnodes[7].parse_keys_list(DictRequiredKey, result.dict_members)
    result.single_keys =
      defnodes[8].parse_keys_list(SingleKey, result.dict_members)
    validate_separators(result.sep, result.dict_internal_sep,
                        DictInternalSepKey,"name/value")
    result.validate_implicit
    result.validate_names_vs_separators
  except YamlSupportError, DefSyntaxError:
    reraise_as_def_syntax_error(name, SyntaxHelp, DefKey)
