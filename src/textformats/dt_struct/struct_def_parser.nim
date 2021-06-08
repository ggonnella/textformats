import options
import strformat
import sets
import yaml/dom
import ../types / [datatype_definition, def_syntax, textformats_error]
import ../shared / [formatting_def_parser, null_value_def_parser,
                    implicit_def_parser, nameddef_def_parser]
import ../support / [yaml_support, error_support, openrange]

proc newStructDatatypeDefinition*(defroot: YamlNode, name: string):
                                  DatatypeDefinition
import ../def_parser

const
  DefKey = StructDefKey
  NRequiredHelp = "Number of required elements (default: all)"
  SyntaxHelp = &"""
  <datatype_name>:
    {DefKey}:
      - <x1>: <y1>
      - <x2>: <y2>
      - ...
    [optional keys]

  where:
  - 'x<N>' is a key name (string)
  - 'y<N>' is either:
    - a datatype name (string); or
    - a datatype definition (map)

  Optional keys:
  - {SepKey}: {SepHelp}
  - {SepExclKey}: {SepExclHelp}
  - {NullValueKey}: {NullValueHelp}
  - {ImplicitKey}: {ImplicitHelp}
  - {NRequiredKey}: {NRequiredHelp}
  """

proc parse_struct_members(n: YamlNode, name: string):
                   seq[(string, DatatypeDefinition)] =
  result = n.parse_named_definitions_to_seq(name, DefKey)
  n.validate_min_len(1, &"Invalid length of '{DefKey}' content.\n")

proc parse_n_required(dd: var DatatypeDefinition, opt_n: Option[YamlNode]) =
  if opt_n.is_none:
    dd.n_required = dd.members.len
  else:
    let n = opt_n.unsafe_get
    n.validate_is_int("Wrong number of required elements\n")
    let n_required = n.to_int
    if n_required < 0:
      raise newException(DefSyntaxError,
              "Number of required elements < 0\n" &
              &"Number of required elements: {n_required}")
    if n_required > dd.members.len:
      raise newException(DefSyntaxError,
              "Number of required elements > number of elements\n" &
              &"Number of required elements: {n_required}\n" &
              &"Number of elements: {dd.members.len}")
    dd.n_required = n_required

proc validate_member_names_uniqueness(dd: DatatypeDefinition) =
  var member_names: HashSet[string]
  for member in dd.members:
    if member.name in member_names:
      raise newException(NodeValueError,
               &"Member name is not unique {member.name}\n")
    member_names.incl(member.name)
  for implicit_member in dd.implicit:
    if implicit_member.name in member_names:
      raise newException(DefSyntaxError,
               &"Implicit member name is equal to a member name\n" &
               &"Duplicated name: {implicit_member.name}\n")

proc newStructDatatypeDefinition*(defroot: YamlNode, name: string):
                                  DatatypeDefinition {.noinit.} =
  try:
    let defnodes = collect_defnodes(defroot,
                     [DefKey, NullValueKey, SepKey, PfxKey, SfxKey,
                      SepExclKey, NRequiredKey, ImplicitKey])
    result = DatatypeDefinition(kind: ddkStruct, name: name,
               members:    defnodes[0].unsafe_get.parse_struct_members(name),
               null_value: defnodes[1].parse_null_value,
               sep:        defnodes[2].parse_sep,
               pfx:        defnodes[3].parse_pfx,
               sfx:        defnodes[4].parse_sfx,
               sep_excl:   defnodes[5].parse_sep_excl,
               implicit:   defnodes[7].parse_implicit)
    result.parse_n_required(defnodes[6])
    validate_sep_if_sepexcl(defnodes[5], defnodes[2])
    result.validate_member_names_uniqueness
  except YamlSupportError, DefSyntaxError, ValueError:
    reraise_as_def_syntax_error(name, SyntaxHelp, DefKey)
