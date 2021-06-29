##
## Parse a YAML specification and create a Specification object
## which contains a DatatypeDefinition object for each definition
##

import streams, strformat, tables, options, os, sets, strutils
import regex
import yaml, yaml / [dom,serialization, hints]
import types / [specification, def_syntax, textformats_error]
import support / [yaml_support, error_support]
import regex_generator, ref_solver, def_parser

const
  IdentifierRE = "[A-Za-z_][A-Za-z_0-9]*".re
  IdentifierHelp = " must be valid C identifiers, i.e. " &
                   "be non empty strings,\nstarting with a letter and " &
                   "consisting of only letters, digits and underscores.\n" &
                   "The identifiers are case sensitive."
  NamespacedHelp = "For special purposes (redefinition of a datatype in " &
                   "included file; definition of a missing datatype in an " &
                   "incompleted included file), datatype names can be " &
                   "identifiers prefixed by one or multiple namespace names " &
                   "concatenated to each other, and to the datatype " &
                   "identifier by {NamespaceSeparator} (e.g. a::b::c)."

proc parse_datatype_name(datatype_name_node: YamlNode): string =
  try:
    datatype_name_node.validate_is_string("Invalid datatype name.\n")
  except NodeValueError:
    raise newException(IdentifierError, get_current_exception_msg())
  result = datatype_name_node.to_string
  if result in BaseDatatypes:
    raise newException(IdentifierError,
             &"The datatype name '{result}' is reserved.\n")

proc include_yaml(spec: Specification, filename: string,
                  datatypes: Option[HashSet[string]],
                  prefix: string,
                  disable_including_incomplete_specs = false,
                  use_namespace = true)

proc get_map_node(n: YamlNode, key: string): Option[YamlNode] {.inline.} =
  # ignore ProveInit warning thrown by options library
  {.warning[ProveInit]: off.}
  try:
    let v = n[key]
    return some(v)
  except KeyError:
    return none(YamlNode)

proc get_datatypes_node(root: YamlNode): Option[YamlNode] =
  result = YamlNode.none
  try:
    let whole_errmsg = "Expected: mapping; allowed keys: " &
                       &"'{DatatypesKey}', '{IncludeKey}', '{NamespaceKey}'"
    root.validate_is_mapping("Invalid content of YAML\n", "\n" & whole_errmsg)
    result = root.get_map_node(DatatypesKey)
    if result.is_some:
      result.unsafe_get.validate_is_mapping(
        &"Invalid content of '{DatatypesKey}' key\n",
        "It must be a mapping containing datatype definitions")
    else:
      if root.get_map_node(IncludeKey).is_none:
        raise newException(InvalidSpecError,
          "Invalid content of YAML mapping\n" & whole_errmsg)
  except NodeValueError:
    raise newException(InvalidSpecError, get_current_exception_msg())

proc do_include(spec: Specification, path: string, filename: string,
                prefix: string, datatypes: Option[HashSet[string]]) =
  try:
    spec.include_yaml(path / filename, datatypes, prefix)
  except YamlParserError:
    raise newException(YamlParserError,
            "Error while parsing included " &
            &"specification: '{filename}'\n" &
            &"Included filename: {path / filename}\n" &
            get_current_exception_msg().indent(2))

proc include_subspec_selection(spec: Specification, filename_map: YamlNode,
                          path: string, prefix: string,
                          datatypes: Option[HashSet[string]]) =
  let errmsg = &"Invalid syntax of '{IncludeKey}' key\n" &
     "Mappings must contain a single key (filename) mapped to a " &
     "list of strings (datatype names)"
  filename_map.validate_len(1, errmsg)
  var
    filename: string
    include_datatypes: HashSet[string]
  if datatypes.is_some:
    include_datatypes = datatypes.unsafe_get
  for filename_node, dt_seq_node in filename_map:
    filename_node.validate_is_string(errmsg)
    filename = filename_node.to_string
    dt_seq_node.validate_is_sequence(errmsg)
    dt_seq_node.validate_min_len(1, errmsg)
    if datatypes.is_none:
      for dtname_node in dt_seq_node:
        dtname_node.validate_is_string(errmsg)
        include_datatypes.incl(dtname_node.to_string)
  spec.do_include(path, filename, prefix, include_datatypes.some)

proc include_subspec(spec: Specification, root: YamlNode, path: string,
                     prefix: string, datatypes: Option[HashSet[string]]) =
  let include_optnode = get_map_node(root, IncludeKey)
  if include_optnode.is_some:
    let include_node = include_optnode.unsafe_get
    try:
      case include_node.kind:
      of yScalar:
        include_node.validate_is_string(
              &"Invalid content of '{IncludeKey}' key\n")
        spec.do_include(path, include_node.to_string, prefix, datatypes)
      of ySequence:
        for filename_node in include_node:
          case filename_node.kind:
          of yScalar:
            filename_node.validate_is_string(
              &"Invalid content of '{IncludeKey}' key\n")
            spec.do_include(path, filename_node.to_string, prefix, datatypes)
          of yMapping:
            spec.include_subspec_selection(filename_node, path,
                                           prefix, datatypes)
          of ySequence:
            raise newException(SpecIncludeError,
                    &"Invalid value in '{IncludeKey}' key YAML sequence\n" &
                    "Sequence values must be strings (filenames) or maps " &
                    "of filenames to YAML sequences of strings (datatype names)")
          filename_node.validate_is_scalar(
                           &"Invalid value in '{IncludeKey}' key YAML sequence\n",
                            "Sequence values must be strings (filenames)")
      of yMapping:
        spec.include_subspec_selection(include_node, path, prefix, datatypes)
    except NodeValueError:
      raise newException(SpecIncludeError, get_current_exception_msg())

proc get_yaml_root(filename: string): YamlNode =
  get_yamlfile_mapping_root(TextformatsRuntimeError,
                            InvalidSpecError, filename,
                            "specification")

proc finalize_definitions(spec: Specification) {.inline.} =
  spec.validate_dependencies
  spec.resolve_references
  spec.compute_regexes

proc validate_datatype_name(name: string, spec: Specification,
                            forbid_overriding_definitions = false) {.inline.} =
  for part in name.split(NamespaceSeparator):
    if not part.match(IdentifierRE):
      raise newException(IdentifierError,
              &"Datatype name invalid: {name}\n" &
              "Datatype names" & IdentifierHelp & "\n\n" &
              NamespacedHelp & "\n")
  if forbid_overriding_definitions:
    if name in spec:
      raise newException(IdentifierError,
                "Datatype definition overriding disabled\n" &
                &"Datatype name: {name}\n" &
                "The datatype name was defined in an included specification\n" &
                "(directly or in a specification included in them)\n")

proc define_datatypes(spec: Specification, root: YamlNode,
                      selection: Option[HashSet[string]],
                      prefix: string) {.inline.} =
  let opt_datatypes_node = root.get_datatypes_node
  if opt_datatypes_node.is_some:
    let datatypes_node = opt_datatypes_node.unsafe_get
    for name_node, defnode in datatypes_node.pairs:
      let name = name_node.parse_datatype_name
      name.validate_datatype_name(spec)
      if selection.is_none or name in selection.unsafe_get:
        let qualified_name = prefix & name
        spec[qualified_name] = newDatatypeDefinition(defnode, qualified_name)

proc compute_datatypes_prefix(root: YamlNode): string =
  let namespace_optnode = get_map_node(root, NamespaceKey)
  if namespace_optnode.is_some:
    let namespace_node = namespace_optnode.unsafe_get
    namespace_node.validate_is_string(
              &"Invalid content of '{NamespaceKey}' key\n")
    let namespace = namespace_node.to_string
    if not namespace.match(IdentifierRE):
      raise newException(IdentifierError,
              "Namespace invalid\n" &
              "Namespaces " & IdentifierHelp & "\n")
    return namespace & NamespaceSeparator

proc include_yaml(spec: Specification, filename: string,
                  datatypes: Option[HashSet[string]],
                  prefix: string,
                  disable_including_incomplete_specs = false,
                  use_namespace = true) =
  let root = filename.get_yaml_root
  try:
    let fullprefix = block:
      if use_namespace: prefix & compute_datatypes_prefix(root)
      else: prefix
    spec.include_subspec(root, split_path(filename).head, fullprefix, datatypes)
    spec.define_datatypes(root, datatypes, fullprefix)
    if disable_including_incomplete_specs:
      spec.finalize_definitions
  except:
    let e = get_current_exception()
    e.msg = yamlfile_errmsg(filename, "specification", e.msg)
    raise e

proc try_finalizing_definitions(spec: Specification, filename: string)
                                {.inline.} =
  try:
    spec.finalize_definitions
  except:
    let e = get_current_exception()
    e.msg = yamlfile_errmsg(filename, "specification", e.msg)
    raise e

proc parse_specification*(filename: string): Specification =
  result = newSpecification()
  result.include_yaml(filename, HashSet[string].none, "",
                      use_namespace = false)
  result.try_finalizing_definitions(filename)

proc specification_from_file*(specfile: string): Specification =
  ## Load specification if specfile is a preprocessed specification file
  ## otherwise parse the file, assuming it is a YAML specification file
  if specfile.is_preprocessed: load_specification(specfile)
  else: parse_specification(specfile)

proc preprocess_specification*(inputfile: string, outputfile: string) =
  ## Parse YAML specification and output preprocessed specification
  let spec = parse_specification(inputfile)
  spec.save_specification(outputfile)

proc list_specification_datatypes*(filename: string): seq[string] =
  ## List the datatypes in a yaml specification file
  ## omitting the included files.
  ##
  ## Note: the input file is not fully validated.
  result = newSeq[string]()
  let
    root = filename.get_yaml_root
    opt_datatypes_node = root.get_datatypes_node
  if opt_datatypes_node.is_some:
    let datatypes_node = opt_datatypes_node.unsafe_get
    for name_node, definition_node in datatypes_node.pairs:
      let name = name_node.parse_datatype_name
      if name notin BaseDatatypes:
        result.add(name)
