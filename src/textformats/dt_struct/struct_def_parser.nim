import options
import strformat
import sets
import yaml/dom
import ../types / [datatype_definition, def_syntax, textformats_error]
import ../shared / [formatting_def_parser, null_value_def_parser,
                    implicit_def_parser, nameddef_def_parser,
                    as_string_def_parser, scope_def_parser]
import ../support / [yaml_support, error_support, messages_support]

proc newStructDatatypeDefinition*(defroot: YamlNode, name: string):
                                  DatatypeDefinition
import ../def_parser

const
  DefKey = StructDefKey
  NRequiredHelp = "Number of required elements (default: all)"
  HiddenHelp = "Hide constant elements from decoded value"
  CombineNestedHelp = "Combine nested structs (keys are joined by .)"
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

  Optional keys for formatting:
  - {PfxKey}: {PfxHelp}
  - {SfxKey}: {SfxHelp}
  - {SepKey}: {SepHelp}
  - {SplittedKey}: {SplittedLastHelp}

  Optional keys for validation:
  - {NRequiredKey}: {NRequiredHelp}

  Optional keys for decoding:
  - {ImplicitKey}: {ImplicitHelp}
  - {CombineNestedKey}: {CombineNestedHelp}
  - {HiddenKey}: {HiddenHelp}
  - {NullValueKey}: {NullValueHelp}
  - {AsStringKey}: {AsStringHelp}
  - {ScopeKey}: {ScopeHelp}
  - {UnitsizeKey}: {UnitsizeHelp}
  """

proc parse_struct_members(n: YamlNode, name: string):
                   seq[(string, DatatypeDefinition)] =
  result = n.parse_named_definitions_to_seq(name, DefKey)
  n.validate_min_len(1, &"Invalid length of '{DefKey}' content.\n")

proc postvalidate_merge_keys(dd: DatatypeDefinition) =
  var assigned_keys = initHashSet[string]()
  var i = 0
  for key in dd.merge_keys:
    i+=1
    var mdef: DatatypeDefinition
    for m in dd.members:
      if m[0] == key:
        mdef = dereference(m[1])
        break
    if mdef.kind != ddkStruct:
      raise newException(DefSyntaxError, "Invalid value found " &
                         &"in '{MergeKeysKey}' list\n" &
                         &"The {nth(i)} element is invalid.\n" &
                         &"'{key}' is not of type 'composed_of'.\n")
    for m2 in mdef.members:
      if m2[0] in assigned_keys:
        raise newException(DefSyntaxError, "Invalid value found " &
                           &"in '{MergeKeysKey}' list\n" &
                           &"The {nth(i)} element is invalid.\n" &
                           &"'{key}' contains {m2[0]}.\n" &
                           &"An element '{m2[0]}' was already assigned.\n")
      assigned_keys.incl(m2[0])

proc postvalidate_struct*(dd: DatatypeDefinition) =
  if dd.merge_keys.len > 0:
    postvalidate_merge_keys(dd)

proc parse_merge_keys(optnode: OptYamlNode,
                      members: seq[(string, DatatypeDefinition)]): seq[string] =
  var member_keys = initHashSet[string]()
  for (key, _) in members:
    member_keys.incl(key)
  result = newSeq[string]()
  if not optnode.is_none:
    let node = optnode.unsafe_get
    node.validate_is_sequence(&"Invalid value of '{MergeKeysKey}'.\n" &
                              "Expected list of strings.\n")
    var i = 0
    for elemnode in node.elems:
      i+=1
      elemnode.validate_is_string("Invalid value found " &
                                &"in '{MergeKeysKey}' list\n" &
                                &"The {nth(i)} element is invalid.\n" &
                                "All elements should be strings.\n")
      let elem = elemnode.to_string
      if elem notin member_keys:
        raise newException(DefSyntaxError, "Invalid value found " &
                           &"in '{MergeKeysKey}' list\n" &
                           &"The {nth(i)} element is invalid.\n" &
                           &"'{elem}' is not the name of an element.\n")
      result.add(elem)

proc parse_n_required(dd: var DatatypeDefinition, opt_n: OptYamlNode) =
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
    dd.n_required = n_required.int

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
  var errmsg = ""
  try:
    let defnodes = collect_defnodes(defroot,
                     [DefKey, NullValueKey, SepKey, PfxKey, SfxKey,
                      SplittedKey, NRequiredKey, ImplicitKey, AsStringKey,
                      HiddenKey, ScopeKey, UnitsizeKey, CombineNestedKey,
                      MergeKeysKey])
    result = DatatypeDefinition(kind: ddkStruct, name: name,
               members:    defnodes[0].unsafe_get.parse_struct_members(name),
               null_value: defnodes[1].parse_null_value,
               pfx:        defnodes[3].parse_pfx,
               sfx:        defnodes[4].parse_sfx,
               implicit:   defnodes[7].parse_implicit,
               as_string:  defnodes[8].parse_as_string,
               scope:      defnodes[10].parse_scope,
               unitsize:   defnodes[11].parse_unitsize)
    result.combine_nested =
      defnodes[12].to_bool(default=false, CombineNestedKey)
    result.merge_keys = defnodes[13].parse_merge_keys(result.members)
    result.parse_n_required(defnodes[6])
    let (sep, sep_excl) = parse_sep(defnodes[2], defnodes[5])
    result.sep = sep
    result.sep_excl = sep_excl
    result.validate_member_names_uniqueness
    if defnodes[9].to_bool(default=false, HiddenKey):
      var i = 0
      for m in result.members:
        if m.def.kind == ddkConst:
          result.hidden.add(i)
        i+=1
  except YamlSupportError, DefSyntaxError, ValueError:
    errmsg = getCurrentException().msg
  raise_if_had_error(errmsg, name, SyntaxHelp, DefKey)
