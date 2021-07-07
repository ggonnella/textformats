##
## Support functions for the DOM API of NimYAML
##

import strformat, tables, json, options, streams, os
import yaml / [dom, serialization, taglib, hints]
import error_support

type
  YamlSupportError* = object of CatchableError
  NodeValueError*   = object of YamlSupportError
  KeyMissingError*  = object of YamlSupportError
  KeyUnknownError*  = object of YamlSupportError

let tlib = initCoreTagLibrary()

# private, exported because it is used by public templates
proc PRV_has_kind*(n: YamlNode, expected: YamlNodeKind): bool =
  n.kind == expected

template is_scalar*(n: YamlNode): bool = n.PRV_has_kind(yScalar)

template is_mapping*(n: YamlNode): bool = n.PRV_has_kind(yMapping)

template is_sequence*(n: YamlNode): bool = n.PRV_has_kind(ySequence)

# private, exported because it is used by public templates
proc PRV_validate_kind*(n: YamlNode, expected: YamlNodeKind, emsg_pfx: string,
                       emsg_sfx: string) =
  if not n.PRV_has_kind(expected):
    raise newException(NodeValueError, emsg_pfx &
                         "\nNode is of " & $n.kind & " kind\n" &
                         "Expected: " & $expected & " kind\n" &
                         emsg_sfx)

# private, exported because it is used by public templates
proc PRV_validate_not_kind*(n: YamlNode, not_expected: YamlNodeKind,
                       emsg_pfx: string, emsg_sfx: string) =
  if n.PRV_has_kind(not_expected):
    raise newException(NodeValueError, emsg_pfx &
                         "\nNode is of " & $n.kind & " kind but should not\n" &
                         emsg_sfx)

template validate_is_scalar*(n: YamlNode, emsg_pfx="", emsg_sfx="") =
  n.PRV_validate_kind(yScalar, emsg_pfx, emsg_sfx)

template validate_is_mapping*(n: YamlNode, emsg_pfx="", emsg_sfx="") =
  n.PRV_validate_kind(yMapping, emsg_pfx, emsg_sfx)

template validate_is_sequence*(n: YamlNode, emsg_pfx="", emsg_sfx="") =
  n.PRV_validate_kind(ySequence, emsg_pfx, emsg_sfx)

template validate_is_not_scalar*(n: YamlNode, emsg_pfx="", emsg_sfx="") =
  n.PRV_validate_not_kind(yScalar, emsg_pfx, emsg_sfx)

template validate_is_not_mapping*(n: YamlNode, emsg_pfx="", emsg_sfx="") =
  n.PRV_validate_not_kind(yMapping, emsg_pfx, emsg_sfx)

template validate_is_not_sequence*(n: YamlNode, emsg_pfx="", emsg_sfx="") =
  n.PRV_validate_not_kind(ySequence, emsg_pfx, emsg_sfx)

template validate_tag_or_guesstype*(n: YamlNode,
                                   condition_met: bool,
                                   name: string,
                                   emsg_pfx: string,
                                   emsg_sfx: string) =
  if not condition_met:
    var tagstr = n.tag
    if n.is_scalar:
      if tlib.tags[tagstr] == yTagQuestionMark:
        tagstr &= "\nNode guessed type: " & $guesstype(n.content)
    raise newException(NodeValueError, emsg_pfx & "\n" &
                         "Node: " & $n & "\n" &
                         "Node is not " & name &
                         "\nNode tag: " & tagstr & "\n" & emsg_sfx)

template guessed_null(n): bool = guesstype(n.content) == yTypeNull

template guessed_int(n): bool = guesstype(n.content) == yTypeInteger

template guessed_float(n): bool =
  let guess = guesstype(n.content)
  guess == yTypeFloat or guess == yTypeFloatInf or guess == yTypeFloatNaN

template guessed_bool(n): bool =
  let guess = guesstype(n.content)
  guess == yTypeBoolTrue or guess == yTypeBoolFalse

template guessed_string(n): bool = guesstype(n.content) == yTypeUnknown

template is_null*(n: YamlNode): bool =
  if not n.is_scalar:
    false
  else:
    let tag = tlib.tags[n.tag]
    tag == yTagNull or (tag == yTagQuestionMark and guessed_null(n))

template is_int*(n: YamlNode): bool =
  if not n.is_scalar:
    false
  else:
    let tag = tlib.tags[n.tag]
    tag == yTagInteger or (tag == yTagQuestionMark and guessed_int(n))

template is_float*(n: YamlNode): bool =
  if not n.is_scalar:
    false
  else:
    let tag = tlib.tags[n.tag]
    tag == yTagFloat or (tag == yTagQuestionMark and guessed_float(n))

template is_bool*(n: YamlNode): bool =
  if not n.is_scalar:
    false
  else:
    let tag = tlib.tags[n.tag]
    tag == yTagBoolean or (tag == yTagQuestionMark and guessed_bool(n))

template is_string*(n: YamlNode): bool =
  if not n.is_scalar:
    false
  else:
    let tag = tlib.tags[n.tag]
    tag == yTagString or tag == yTagExclamationMark or
                         (tag == yTagQuestionMark and guessed_string(n))

template validate_is_null*(n: YamlNode, emsg_pfx="", emsg_sfx="") =
  n.validate_tag_or_guesstype(n.is_null(), "null", emsg_pfx, emsg_sfx)

template validate_is_int*(n: YamlNode, emsg_pfx="", emsg_sfx="") =
  n.validate_tag_or_guesstype(n.is_int(), "integer", emsg_pfx, emsg_sfx)

template validate_is_float*(n: YamlNode, emsg_pfx="", emsg_sfx="") =
  n.validate_tag_or_guesstype(n.is_float(), "float", emsg_pfx, emsg_sfx)

template validate_is_bool*(n: YamlNode, emsg_pfx="", emsg_sfx="") =
  n.validate_tag_or_guesstype(n.is_bool(), "boolean", emsg_pfx, emsg_sfx)

template validate_is_string*(n: YamlNode, emsg_pfx="", emsg_sfx="") =
  n.validate_tag_or_guesstype(n.is_string(), "string", emsg_pfx, emsg_sfx)

converter to_int*(n: YamlNode): int =
  n.validate_is_int(); n.content.load(result)

converter to_uint*(n: YamlNode): uint =
  var tmp: int
  n.validate_is_int()
  if n < 0:
    raise newException(NodeValueError,
            "Invalid value for unsigned integer (< 0)")
  n.content.load(tmp)
  return tmp.uint

converter to_natural*(n: YamlNode): Natural =
  var tmp: Natural
  n.validate_is_int()
  if n < 0:
    raise newException(NodeValueError,
            "Invalid value for non-negative integer (< 0)")
  n.content.load(tmp)
  return tmp.Natural

converter to_float*(n: YamlNode): float =
  n.validate_is_float(); n.content.load(result)

converter to_bool*(n: YamlNode): bool =
  n.validate_is_bool(); n.content.load(result)

converter to_string*(n: YamlNode): string =
  n.validate_is_string(); result = n.content #.load(result)

converter to_opt_int*(n: Option[YamlNode]): Option[int] =
  if n.is_some: n.unsafe_get.to_int.some else: int.none

converter to_opt_uint*(n: Option[YamlNode]): Option[uint] =
  if n.is_some: n.unsafe_get.to_uint.some else: uint.none

converter to_opt_natural*(n: Option[YamlNode]): Option[Natural] =
  if n.is_some: n.unsafe_get.to_natural.some else: Natural.none

converter to_opt_float*(n: Option[YamlNode]): Option[float] =
  if n.is_some: n.unsafe_get.to_float.some else: float.none

converter to_opt_bool*(n: Option[YamlNode]): Option[bool] =
  if n.is_some: n.unsafe_get.to_bool.some else: bool.none

converter to_opt_string*(n: Option[YamlNode]): Option[string] =
  if n.is_some: n.unsafe_get.to_string.some else: string.none

proc to_int*(n: Option[YamlNode], default: int): int =
  if n.is_some: n.unsafe_get.to_int else: default

proc to_int*(n: Option[YamlNode], default: int, name: string): int =
  try:
    result = n.to_int(default=default)
  except NodeValueError:
    reraise_prepend(&"Invalid value for '{name}'.\n")

proc to_uint*(n: Option[YamlNode], default: uint): uint =
  if n.is_some: n.unsafe_get.to_uint else: default

proc to_uint*(n: Option[YamlNode], default: uint, name: string): uint =
  try:
    result = n.to_uint(default=default)
  except NodeValueError:
    reraise_prepend(&"Invalid value for '{name}'.\n")

proc to_natural*(n: Option[YamlNode], default: Natural): Natural =
  if n.is_some: n.unsafe_get.to_natural else: default

proc to_natural*(n: Option[YamlNode], default: Natural, name: string): Natural =
  try:
    result = n.to_natural(default=default)
  except NodeValueError:
    reraise_prepend(&"Invalid value for '{name}'.\n")

proc to_float*(n: Option[YamlNode], default: float): float =
  if n.is_some: n.unsafe_get.to_float else: default

proc to_float*(n: Option[YamlNode], default: float, name: string): float =
  try:
    result = n.to_float(default=default)
  except NodeValueError:
    reraise_prepend(&"Invalid value for '{name}'.\n")

proc to_bool*(n: Option[YamlNode], default: bool): bool =
  if n.is_some: n.unsafe_get.to_bool else: default

proc to_bool*(n: Option[YamlNode], default: bool, name: string): bool =
  try:
    result = n.to_bool(default=default)
  except NodeValueError:
    reraise_prepend(&"Invalid value for '{name}'.\n")

proc to_string*(n: Option[YamlNode], default: string): string =
  if n.is_some: n.unsafe_get.to_string else: default

proc to_string*(n: Option[YamlNode], default: string, name: string): string =
  try:
    result = n.to_string(default=default)
  except NodeValueError:
    reraise_prepend(&"Invalid value for '{name}'.\n")

when is_main_module:
  {.warning[ObservableStores]: off.}
  {.warning[ProveInit]: off.}
  var yamldoc = load_dom("0")
  do_assert is_int(yamldoc.root)
  yamldoc = load_dom("\"0\"")
  do_assert not is_int(yamldoc.root)
  yamldoc = load_dom("'0'")
  do_assert not is_int(yamldoc.root)
  yamldoc = load_dom("!!int '3'")
  do_assert is_int(yamldoc.root)
  do_assert yamldoc.root + 1 == 4
  yamldoc = load_dom("'1'")
  do_assert not is_int(yamldoc.root)

converter to_json_node*(n: YamlNode): JsonNode {.noInit.} =
  if n.is_null:     result = newJNull()
  elif n.is_int:    result = %*(n.to_int)
  elif n.is_float:  result = %*(n.to_float)
  elif n.is_bool:   result = %*(n.to_bool)
  elif n.is_string: result = %*(n.to_string)
  elif n.is_sequence:
    result = newJArray()
    for e in n.elems:
      result.add(e.to_json_node)
  elif n.is_mapping:
    result = newJObject()
    for k, v in n.pairs:
      # strictly: k should be a string
      # however: this converter is used for simple representation of YamlNode
      #          in error messages, thus should possibly never fail
      # thus: use its json representation in case it's not a string
      let key =
        if k.is_string: k.to_string
        else: $(k.to_json_node)
      result[key] = v.to_json_node

converter to_opt_json_node*(n: Option[YamlNode]): Option[JsonNode] {.noInit.} =
  if n.is_none: JsonNode.none
  else: n.unsafe_get.to_json_node.some

proc accepted_keys_helpmsg(keys: openArray[string], n_required: int): string =
  assert len(keys) > 0
  if len(keys) == 1:
    if n_required == 0:
      result = &"Only key '{keys[0]}' is accepted."
    else:
      result = &"Key '{keys[0]}' is incompatible with all other keys."
  else:
    result = &"The following keys are allowed, when key '{keys[0]}' is present:"
    for i, key in keys:
      if i < n_required:
        result &= &"\n'{key}' (required key)"
      else:
        result &= &"\n'{key}' (optional key)"

template validate_condition(n: YamlNode, condition: bool,
                  emsg_pfx: string,
                  emsg: string, emsg_sfx: string) =
  let `condition` = condition
  if not condition:
    raise newException(NodeValueError,
            emsg_pfx & "Invalid: " & $n & "\n" &
            emsg & "\n" & emsg_sfx)

proc validate_has_key*(n: YamlNode, key: string, emsg_pfx = "", emsg_sfx = "") =
  assert n.kind == yMapping
  var found = false
  for k, _ in n:
    if k.content == key:
      found = true
      break
  n.validate_condition(found, emsg_pfx, &"Key not found: '{key}'", emsg_sfx)

proc validate_len*(n: YamlNode, expected_len: int,
                   emsg_pfx = "", emsg_sfx = "") =
  assert n.kind != yScalar
  n.validate_condition(len(n) == expected_len, emsg_pfx,
             &"Invalid length: {len(n)}\nExpected length: {expected_len}",
             emsg_sfx)

proc validate_min_len*(n: YamlNode, expected_min_len: int,
                   emsg_pfx = "", emsg_sfx = "") =
  assert n.kind != yScalar
  n.validate_condition(len(n) >= expected_min_len, emsg_pfx,
            &"Invalid length: {len(n)}\nExpected length: >= {expected_min_len}",
            emsg_sfx)

proc getKeys*(n: YamlNode,
              keys: openArray[string],
              n_required: int,
              errmsgpfx = ""):
              seq[Option[YamlNode]] =
  ## Validate a map YAML node with a set of predefined keys and
  ## collect the corresponding values.
  ##
  ## Arguments:
  ## - ``keys``: _required_ keys, followed by _optional_ keys
  ## - ``n_required``: how many of the keys are _required_
  ##                   (integer between ``0`` and ``len(keys)``)
  ##
  ## Return value:
  ## - map values in the same order as the keys in ``keys``; type:
  ##   - ``some(YamlNode)`` for all required keys
  ##   - ``some(YamlNode)`` for the optional keys found in the map
  ##   - ``none(YamlNode)`` for the optional keys not found in the map
  ##
  ## Exceptions raised:
  ## - NodeValueError: if the node is not a map node
  ## - KeyUnknownError: if a map key is not in the ``keys`` list
  ## - KeyMissingError: if a required map key is not present
  {.warning[ProveInit]: off.}
  newSeq(result, len(keys))
  assert(n_required >= 0 and n_required <= len(keys))
  assert not n.isnil
  validate_is_mapping(n)
  for found_key_node, value_node in n.pairs:
    var known = false
    let key = found_key_node.content
    for i, accepted_key in keys.pairs:
      if key == accepted_key:
        known = true
        result[i] = some[YamlNode](value_node)
    if not known:
      raise newException(KeyUnknownError,
        &"{errmsgpfx}Invalid key: '{key}'\n" &
        accepted_keys_helpmsg(keys, n_required))
  for i in 0..<n_required:
    if result[i].is_none:
      raise newException(KeyMissingError,
        &"{errmsgpfx}Missing key: '{keys[i]}'\n" &
        accepted_keys_helpmsg(keys, n_required))

template yamlparse_errmsg*(filename: string, desc: string,
                          errmsg: string): string =
  let fn = if len(filename) > 0: "Filename: '" & filename & "'\n" else: ""
  "Error parsing " & desc & "\n" & (fn & errmsg).indent(2)

proc get_yaml_mapping_root*(io_errtype: typedesc, parsing_errtype: typedesc,
                            input: string, strinput: bool,
                            inputdesc: string): YamlNode =
  var
    stream: Stream = nil
    yaml: YamlDocument = YamlDocument(root: YamlNode())
  let fn = if strinput: "" else: input
  try:
    if strinput:
      stream = newStringStream(input)
    elif input == "":
      stream = newFileStream(stdin)
    else:
      if not fileExists(input):
        raise newException(io_errtype, yamlparse_errmsg(inputdesc,
                           "File not found", fn))
      stream = newFileStream(input, fmRead)
  except IOError:
    raise newException(io_errtype, yamlparse_errmsg(inputdesc,
       get_current_exception_msg(), fn))
  try:
    yaml = load_dom(stream)
    stream.close
  except:
    raise newException(parsing_errtype,
       yamlparse_errmsg(inputdesc,
         get_current_exception_msg(), fn))
  try:
    yaml.root.validate_is_mapping()
  except NodeValueError:
    raise newException(parsing_errtype, yamlparse_errmsg(
      inputdesc,
      "Expected: " &
      "The root node must be a mapping.\n" &
      "Details of the validation error:" &
      get_current_exception_msg().indent(2),
      fn))
  return yaml.root

