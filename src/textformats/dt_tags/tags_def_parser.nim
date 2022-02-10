import strformat, tables, sequtils, strutils
import yaml
import regex
import ../support / [yaml_support, error_support]
import ../types / [datatype_definition, def_syntax, textformats_error]
import ../shared / [formatting_def_parser, implicit_def_parser,
                    null_value_def_parser, nameddef_def_parser,
                    as_string_def_parser]

proc newTagsDatatypeDefinition*(defroot: YamlNode, name: string):
                                DatatypeDefinition
import ../def_parser

const
  DefKey = TagsDefKey
  PredefinedTagsHelp* = "tags which, if present, must have a given type; " &
                    "{tagname: typekey[, tagname: typekey]*}"
  TagnameDefHelp* = "regular expression for validating tagnames " &
                    "(except predefined tags)"
  DefaultTagsInternalSep = ":"
  DefaultTagnameRegex = "[A-Za-z_][0-9A-Za-z_]*"
  TagsInternalSepHelp* =
    "separator between tagname and tagtype and between tagtype and value " &
                &"(string, default '{DefaultTagsInternalSep}')"

  TagTypeDictKey = "type"
  TagValueDictKey = "value"

  SyntaxHelp = &"""
  <datatype_name>:
    {DefKey}:
      - <t1>: <y1>
      - <t2>: <y2>
      - ...
    {TagnameKey}: ...
    {SplittedKey}: ...
    {TagsInternalSepKey}: ...
    [optional keys]

  where:
  - 't<N>' is the type key,
           i.e. the string which defines the type of the tag (string)
  - 'y<N>' is the value datatype, i.e. it defines which format the
           value has, for the given type; it is either:
    - a datatype name (string); or
    - a datatype definition (map)
  - {TagnameKey}: {TagnameDefHelp}

  Separators:
  - {SplittedKey}: {SplittedHelp}
  - {TagsInternalSepKey}: {TagsInternalSepHelp}
  - the values of '{SplittedKey}' and '{TagsInternalSepKey}' must be non-empty
    strings; the must be different from each other and the value of
    '{TagsInternalSepKey}' cannot contain the value of '{SplittedKey}'
  - limitations: as currently implemented, if the elements contain the
    '{SplittedKey}' value (also in escaped form), the datatype cannot be
    represented using a '{DefKey}' definition

  Optional keys for formatting:
  - {PfxKey}: {PfxHelp}
  - {SfxKey}: {SfxHelp}

  Optional keys for validation:
  - {PredefinedTagsKey}: {PredefinedTagsHelp}

  Optional keys for decoding:
  - {NullValueKey}: {NullValueHelp}
  - {ImplicitKey}: {ImplicitHelp}
  - {AsStringKey}: {AsStringHelp}
  """

proc parse_tagtypes(n: YamlNode, name: string):
                   TableRef[string, DatatypeDefinition] =
  n.parse_named_definitions_to_table(name & ".type", DefKey)

proc parse_predefined_tags(opt_n: Option[YamlNode]): TableRef[string, string] =
  result = newTable[string, string]()
  if opt_n.is_some:
    let n = opt_n.unsafe_get
    n.validate_is_mapping("Invalid value for '" & DefKey & "'.\n")
    for k, v in n:
      k.validate_is_scalar("Invalid value for '" & DefKey & "'.\n")
      v.validate_is_scalar("Invalid value for '" & DefKey & "'.\n")
      result[k.to_string] = v.to_string

proc validate_predefined_tags(d: DatatypeDefinition) =
  for k, v in d.predefined_tags:
    if v notin d.tagtypes:
      raise newException(DefSyntaxError,
                         &"Invalid content of '{PredefinedTagsKey}':\n" &
                         &"  {v} is not one of the defined types " &
                          to_seq(d.tagtypes.keys).join(", "))

proc parse_tags_internal_sep*(node: Option[YamlNode]): string =
  node.to_string(default=DefaultTagsInternalSep, TagsInternalSepKey)

proc validate_names_vs_separators(dd: DatatypeDefinition) =
  let
    tt = to_seq(dd.tagtypes.keys)
    pn = to_seq(dd.predefined_tags.keys)
    ttlbl = "Tag type key"
    pnlbl = "Predefined tag name"
    seplbl = "elements"
    iseplbl = "name/type/value"
  validate_names_vs_separator(tt, ttlbl, dd.sep, seplbl)
  validate_names_vs_separator(tt, ttlbl, dd.tags_internal_sep, iseplbl)
  validate_names_vs_separator(pn, pnlbl, dd.sep, seplbl)
  validate_names_vs_separator(pn, pnlbl, dd.tags_internal_sep, iseplbl)

proc parse_tagname_regex(dd: var DatatypeDefinition, optn: Option[YamlNode]) =
  let invaliderr = "Invalid value for '" & TagnameKey & "'.\n"
  if optn.is_none:
    dd.tagname_regex_raw = DefaultTagnameRegex
  else:
    let n = optn.unsafe_get
    n.validate_is_string(invaliderr)
    dd.tagname_regex_raw = n.to_string
  if len(dd.tagname_regex_raw) > 0:
    try:
      let avoid_warning_tmp = dd.tagname_regex_raw.re
      dd.tagname_regex_compiled = avoid_warning_tmp
    except:
      let e = get_current_exception()
      raise newException(DefSyntaxError, invaliderr &
                         "Error: invalid regular expression syntax.\n" &
                         &"Regular expression: '{dd.tagname_regex_raw}'\n" &
                         e.msg & "\n")
  if len(dd.predefined_tags) > 0:
    var names = to_seq(dd.predefined_tags.keys)
    names.apply(escape_re)
    if len(dd.tagname_regex_raw) > 0:
      names.add(dd.tagname_regex_raw)
    dd.tagname_regex_raw = "(" & names.join("|") & ")"
    let avoid_warning_tmp = dd.tagname_regex_raw.re
    dd.tagname_regex_compiled = avoid_warning_tmp
  if len(dd.tagname_regex_raw) == 0:
    raise newException(DefSyntaxError, invaliderr &
                       "Error: tagnames regular expression cannot be " &
                       "empty if not predefined tagnames are specified.\n")

proc newTagsDatatypeDefinition*(defroot: YamlNode, name: string):
                                DatatypeDefinition {.noinit.} =
  var errmsg = ""
  try:
    let defnodes = collect_defnodes(defroot,
                     [DefKey, SplittedKey, TagnameKey, TagsInternalSepKey,
                     PfxKey, SfxKey, NullValueKey, PredefinedTagsKey,
                     ImplicitKey, AsStringKey], n_required=2)
    result = DatatypeDefinition(kind: ddkTags, name: name,
      tagtypes:          defnodes[0].unsafe_get.parse_tagtypes(name),
      sep:               defnodes[1].to_string("", SplittedKey),
      sep_excl:          true,
      tags_internal_sep: defnodes[3].parse_tags_internal_sep,
      pfx:               defnodes[4].parse_pfx,
      sfx:               defnodes[5].parse_sfx,
      null_value:        defnodes[6].parse_null_value,
      predefined_tags:   defnodes[7].parse_predefined_tags,
      implicit:          defnodes[8].parse_implicit,
      as_string:         defnodes[9].parse_as_string,
      type_key:          TagTypeDictKey,
      value_key:         TagValueDictKey)
    result.validate_predefined_tags
    result.parse_tagname_regex(defnodes[2])
    validate_separators(result.sep, result.tags_internal_sep,
                        TagsInternalSepKey ,"name/type/value")
    result.validate_names_vs_separators
  except YamlSupportError, DefSyntaxError:
    errmsg = getCurrentException().msg
  raise_if_had_error(errmsg, name, SyntaxHelp, DefKey)
