import options, strformat, sets
import yaml/dom
import ../types / [datatype_definition, def_syntax, textformats_error]
import ../support / [yaml_support, error_support, messages_support]
import ../shared / [null_value_def_parser, as_string_def_parser]

proc newUnionDatatypeDefinition*(defroot: YamlNode, name: string):
                                 DatatypeDefinition
import ../def_parser

const
  DefKey = UnionDefKey
  WrappedHelp = "Boolean (default: false); "&
                "if true, the decoded value is wrapped into " &
                "a mapping {branch_name: unwrapped_value}"
  BranchNamesHelp = "branch names to use for wrapping, sequence of strings or " &
                   "the string 'default'; default: the name for a branch x " &
                   "is: datatype name if the x-th branch is a reference " &
                   &"(string); otherwise the name of the '{Defkey}' followed " &
                   "by an ordinal number starting from 1, enclosed in [] "&
                   "(e.g. '<one_of_datatype_name>[1]')"
  SyntaxHelp = &"""
  <datatype_name>:
    {DefKey}:
      - <x1>
      - <x2>
  [optional keys]

  where <xN> are the branches, either:
    - a datatype name (string); or
    - a datatype definition (map)

  Optional keys for decoding:
  - {WrappedKey}: {WrappedHelp}
  - {BranchNamesKey}: {BranchNamesHelp}
  - {NullValueKey}: {NullValueHelp}
  - {AsStringKey}: {AsStringHelp}
  """

proc parse_choices(defnode: YamlNode, name: string): seq[DatatypeDefinition] =
  defnode.validate_is_sequence(&"Invalid value of '{DefKey}'.\n")
  defnode.validate_min_len(2, &"Invalid content of '{DefKey}' list.\n")
  var i = 0
  for node in defnode.elems:
    try:
      let choice_name =
        if node.kind == yScalar: name & "." & node.to_string
        else:                    name & &"[{i}]"
      result.add(newDatatypeDefinition(node, choice_name))
    except YamlSupportError:
      reraise_prepend(&"Invalid element in '{DefKey}' key.\n")
    i += 1

proc parse_branch_names(optnode: Option[YamlNode], name: string,
                        choices_node: YamlNode): seq[string] =
  var assign_defaults = false
  let n_branches = len(choices_node.elems)
  if optnode.is_none:
    assign_defaults = true
  else:
    let node = optnode.unsafe_get
    if node.is_string:
      let node_str = node.to_string
      if node_str == "default":
        assign_defaults = true
      else:
        raise newException(DefSyntaxError,
                &"Invalid value of '{BranchNamesKey}'.\n" &
                &"Invalid string value: {node_str}\n" &
                &"Expected: list of strings or 'auto'\n")
    else:
      node.validate_is_sequence(&"Invalid value of '{BranchNamesKey}'.\n")
      node.validate_len(n_branches,
                        &"Invalid length of '{BranchNamesKey}' list.\n")
      var
        i = 0
        previous = initHashSet[string]()
      for elemnode in node.elems:
        elemnode.validate_is_string("Invalid value found " &
                                  &"in '{BranchNamesKey}' list\n" &
                                  &"The {nth(i+1)} element is invalid.\n" &
                                  "All elements should be strings.\n")
        let elem = elemnode.to_string
        if elem in previous:
          raise newException(DefSyntaxError, "Duplicated value found " &
                                  &"in '{BranchNamesKey}' list\n" &
                                  &"Duplicated value: '{elem}'\n" &
                                  "All elements should be unique.\n")
        previous.incl(elem)
        result.add(elem)
  if assign_defaults:
    for i in 0..<n_branches:
      let choice_name =
        if choices_node[i].kind == yScalar:
          choices_node[i].to_string
        else: &"{name}[{i+1}]"
      result.add(choice_name)

proc newUnionDatatypeDefinition*(defroot: YamlNode, name: string):
                                 DatatypeDefinition {.noinit.} =
  try:
    var defnodes = collect_defnodes(defroot, [DefKey,
                      NullValueKey, AsStringKey, WrappedKey,
                      BranchNamesKey])
    result = DatatypeDefinition(kind: ddkUnion, name: name,
        choices:    defnodes[0].unsafe_get.parse_choices(name),
        null_value: defnodes[1].parse_null_value,
        as_string:  defnodes[2].parse_as_string,
        wrapped:    defnodes[3].to_bool(default=false, WrappedKey))
    result.branch_names = defnodes[4].parse_branch_names(name,
                                        defnodes[0].unsafe_get)
  except YamlSupportError, DefSyntaxError:
    reraise_as_def_syntax_error(name, SyntaxHelp, DefKey)
