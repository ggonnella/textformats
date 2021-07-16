# standard library
import options, tables, strformat, json, strutils
import regex
import match_element, textformats_error
import ../support/openrange

## DatatypeDefinition
##
## The definition of a datatype.
##
## A datatype definition object either is a reference to another datatype
## (kind: ddkRef, resolved or unresolved) or defines a datatype
## as a scalar or compound value (union, array, struct).
##
## A scalar datatype definition is either:
## - a numerical subrange (ddkIntRange or ddkFloatRange); or
## - a list of one or more match constants or regexes
##   which are tested in the order (ddkEnum)
##
## A compound datatype definition is either:
## - a choice among multiple datatypes (union; ddkUnion)
## - a tuple of a fixed number of named members,
##   each of them of possibly a different datatype (struct; ddkStruct)
## - a list of any length, where each element has
##   the same datatype (array; ddkList)
## - a list of any length, where each element has
##   a key determining the semantic and datatype
##   and a value (dict; ddkDict)
## - a list of any length, where each element has
##   a name, a code determining the datatype and
##   a value (tags; ddkTags)
##
type

  DatatypeDefinitionKind* = enum
    # resolved or not-yet-resolved reference to another def
    ddkRef

    # numerical value
    ddkAnyInteger
    ddkAnyUInteger
    ddkAnyFloat
    ddkIntRange
    ddkUIntRange
    ddkFloatRange

    # string value
    ddkAnyString
    ddkRegexMatch
    ddkRegexesMatch

    # numerical or string scalar value/values
    ddkConst
    ddkEnum

    # externally parsed subformats
    ddkJson

    # compound values
    ddkList
    ddkStruct
    ddkDict
    ddkTags
    ddkUnion

  DatatypeRegex* = object
    compiled*: Regex
    raw*: string
    ensures_valid*: bool

  DatatypeDefinitionScope* = enum
    ddsUndef   = "undefined",
    ddsLine    = "line",
    ddsUnit    = "unit",
    ddsSection = "section"
    ddsFile    = "file"

  DatatypeDefinition* = ref DatatypeDefinitionObj
  DatatypeDefinitionObj {.acyclic.} = object

    name*: string
    regex*: DatatypeRegex

    # Encoded string formatting

    sep*: string ## separator string in datatypes consisting of multiple
                 ## elements (lists, structs); may be an empty string;
                 ## ignored in datatypes which do not have multiple elements
    sep_excl*: bool ## whether the separator string is exclusive, i.e.
                    ## not included in the elements (not even escaped);
                    ## ignored if sep is empty or does not apply
    pfx*: string ## fixed prefix string, stripped off before decoding
                 ## the value and prepended to the encoded value
    sfx*: string ## fixed suffix string, stripped off before decoding
                 ## the value and prepended to the encoded value

    # Decoding and encoding rules

    null_value*: Option[JsonNode]   ## decoded value correspoding to an empty
                                    ## encoded string; it has highest priority
    decoded*: seq[Option[JsonNode]] ## value or values to which a
                                    ## valid value shall be mapped
                                    ## (one for each match branching of the
                                    ## datatype; if there is only one, the
                                    ## sequence must have length 1)
    encoded*: Option[TableRef[JsonNode, string]] ##\
                                    ## values to which to encode decoded values;
                                    ## it must contain all values in the decoded
                                    ## list (except those corresponding to
                                    ## match branches where only one
                                    ## encoded string matches)
    implicit*: seq[tuple[name: string, value: JsonNode]] ##\
                                    ## constant additional values to add to
                                    ## table-like decoded values
                                    ## (ddkStruct, ddkDict, ddkTags)
    as_string*: bool ## the definition is only used for validation
                     ## but no decoding or encoding is done, i.e. the
                     ## encoded string is returned as decoded data;
                     ## ignored for datatypes whose decoded value are strings

    # Scope of the definition when decoding files

    scope*: DatatypeDefinitionScope ## if this definition is used for
                                    ## representing a file, which part of
                                    ## the file is covered by the definition

    unitsize*: int                  ## if scope is ddsUnit, which
                                    ## is the size of a unit, in number of lines

    # Kind-specific information

    case kind*: DatatypeDefinitionKind
    of ddkJson,
       ddkAnyInteger, ddkAnyUInteger,
       ddkAnyFloat, ddkAnyString, ddkRegexMatch: discard

    of ddkRef:
      target*: DatatypeDefinition
      target_name*: string

    of ddkIntRange:
      range_i*: OpenRange[int64]

    of ddkUIntRange:
      range_u*: OpenRange[uint64]
      base*: int

    of ddkFloatRange:
      min_f*, max_f*: float
      min_incl*, max_incl*: bool

    of ddkConst:
      constant_element*: MatchElement

    of ddkEnum:
      elements*: seq[MatchElement]

    of ddkRegexesMatch:
      regexes_raw*: seq[string]
      regexes_compiled*: seq[Regex]

    of ddkList:
      members_def*: DatatypeDefinition
      lenrange*: OpenRange[Natural]

    of ddkStruct:
      members*: seq[tuple[name: string, def: DatatypeDefinition]]
      n_required*: int
      hidden*: seq[int]

    of ddkDict:
      dict_members*: TableRef[string, DatatypeDefinition] # name => def
      required_keys*: seq[string]
      single_keys*: seq[string]
      dict_internal_sep*: string

    of ddkTags:
      tagname_regex_raw*: string
      tagname_regex_compiled*: Regex
      tagtypes*: TableRef[string, DatatypeDefinition] # type => value_def
      predefined_tags*: TableRef[string, string] # name => type
      tags_internal_sep*: string
      type_key*: string
      value_key*: string

    of ddkUnion:
      choices*: seq[DatatypeDefinition]
      wrapped*: bool
      branch_names*: seq[string]

    # Construction flags

    has_unresolved_ref*: bool
    regex_computed*: bool

proc children*(dd: DatatypeDefinition): seq[DatatypeDefinition] =
  result = newseq[DatatypeDefinition]()
  case dd.kind:
  of ddkRef: result.add(dd.target)
  of ddkAnyInteger, ddkAnyUInteger, ddkAnyFloat,
     ddkIntRange, ddkUIntRange, ddkFloatRange,
     ddkAnyString, ddkRegexMatch, ddkRegexesMatch,
     ddkConst, ddkEnum, ddkJson: discard
  of ddkList: result.add(dd.members_def)
  of ddkStruct:
    for m in dd.members: result.add(m.def)
  of ddkDict:
    for name, def in dd.dict_members: result.add(def)
  of ddkTags:
    for name, def in dd.tagtypes: result.add(def)
  of ddkUnion:
    for c in dd.choices: result.add(c)

proc dereference*(dd: DatatypeDefinition): DatatypeDefinition =
  result = dd
  while result.kind == ddkRef:
    assert(not result.target.is_nil)
    result = result.target

proc tabular_desc*(d: DatatypeDefinition, indent: int): string
proc verbose_desc*(d: DatatypeDefinition, indent: int): string
proc repr_desc*(d: DatatypeDefinition, indent: int): string

proc parse_scope*(scope: string): DatatypeDefinitionScope =
  let valid_definition_types = @["file", "section", "unit", "line"]
  if scope notin valid_definition_types:
    let scope_errmsg = block:
      var msg = "Error: scope must be one of the following values:\n"
      for t in valid_definition_types:
        msg &= &"- {t}\n"
      msg
    raise newException(TextformatsRuntimeError, scope_errmsg)
  case scope:
  of "file": return ddsFile
  of "section": return ddsSection
  of "unit": return ddsUnit
  of "line": return ddsLine

# "deep" getters and setters

proc get_unitsize*(d: DatatypeDefinition): int =
  let dd = dereference(d)
  dd.unitsize

proc set_unitsize*(d: DatatypeDefinition, unitsize: int) =
  if unitsize < 1:
    raise newException(TextformatsRuntimeError,
                       "Error: unit size must be >= 1\n")
  else:
    let dd = dereference(d)
    dd.unitsize = unitsize

proc get_scope*(d: DatatypeDefinition): string =
  let dd = dereference(d)
  $dd.scope

proc set_scope*(d: DatatypeDefinition, scope: string) =
  let dd = dereference(d)
  dd.scope = parse_scope(scope)

proc get_wrapped*(d: DatatypeDefinition): bool =
  let dd = dereference(d)
  dd.wrapped

proc set_wrapped*(d: DatatypeDefinition) =
  let dd = dereference(d)
  dd.wrapped = true

proc unset_wrapped*(d: DatatypeDefinition) =
  let dd = dereference(d)
  dd.wrapped = false

proc `$`*(dd: DatatypeDefinition): string =
  dd.verbose_desc(0)

proc repr*(dd: DatatypeDefinition): string =
  dd.repr_desc(0)

proc describe(kind: DatatypeDefinitionKind): string =
  case kind:
  of ddkRef: "reference to another definition"
  of ddkAnyInteger: "any integer number"
  of ddkAnyUInteger: "any unsigned integer number"
  of ddkAnyFloat: "any floating point number"
  of ddkIntRange: "range of integer numbers"
  of ddkUIntRange: "range of unsigned integer numbers"
  of ddkFloatRange: "range of floating point numbers"
  of ddkAnyString: "string value"
  of ddkRegexMatch: "string value matching a regular expression"
  of ddkRegexesMatch: "string value " &
                    "matching one of a list of regular expressions"
  of ddkConst: "constant value"
  of ddkEnum: "one of a set of accepted values"
  of ddkJson: "JSON string"
  of ddkList: "list of elements of the same type"
  of ddkStruct: "tuple of elements (of possibly different types)"
  of ddkDict: "list of key/value pairs (key determines semantic " &
            "and datatype of value)"
  of ddkTags: "list of tagname/typecode/value tuples (value semantic " &
            "depends on tagname, datatype on typecode)"
  of ddkUnion: "one of a list of possible datatypes"

proc describe(scope: DatatypeDefinitionScope): string =
  case scope:
  of ddsUndef: "any part of a file (default)"
  of ddsLine: "a single line of a file"
  of ddsUnit: "a fixed number of lines of a file"
  of ddsSection: "a section of a file, with as many " &
                 "lines as fitting the definition"
  of ddsFile: "the entire file"

proc verbose_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx="  ".repeat(indent)
  if d.is_nil:
    return "(nil)"
  if indent == 0:
    result &= "Datatype: "
  else:
    result &= pfx
  result &= &"'{d.name}': {d.kind.describe}\n"
  case d.kind:
  of ddkRef:
    if d.has_unresolved_ref:
      result &= &"\n{pfx}  the target of the reference is: <{d.target_name}>\n"
    else:
      assert not d.target.is_nil
      result &= &"\n{pfx}  the target of the reference is "
      if d.target_name.len > 0:
        result &= &"'{d.target_name}' "
      else:
        result &= "(anonymous) "
      result &= &"defined as:\n"
      result &= d.target.verbose_desc(indent+2)
  of ddkIntRange:
    result &= &"\n{pfx}  the range is {d.range_i}\n"
  of ddkUIntRange:
    result &= &"\n{pfx}  the range is {d.range_u}\n"
    result &= &"\n{pfx}  the integer is in base {d.base}\n"
  of ddkFloatRange:
    result &= &"\n{pfx}  the range is: ({d.min_f},{d.max_f})\n"
    if d.max_incl:
      if d.min_incl:
        result &= &"{pfx}  (including the maximum and the minimum)\n"
      else:
        result &= &"{pfx}  (including the maximum but not the minimum)\n"
    else:
      if d.min_incl:
        result &= &"{pfx}  (including the minimum but not the maximum)\n"
      else:
        result &= &"{pfx}  (not including the minimum and the maximum)\n"
  of ddkConst:
    result &= &"\n{pfx}  the constant value is {d.constant_element}\n"
    if d.decoded[0].is_some:
      result &= &"{pfx}  which is decoded as: {d.decoded[0].unsafe_get}\n"
  of ddkEnum:
    result &= &"\n{pfx}  the accepted values are:\n"
    for i, element in d.elements:
      result &= &"{pfx}    {d.elements[i]}"
      if d.decoded[i].is_some:
        result &= &" decoded as: {d.decoded[i].unsafe_get}"
      result &= "\n"
  of ddkRegexMatch:
    result &= &"\n{pfx}  the regular expression is: '{d.regex.raw}'\n"
    if d.decoded[0].is_some:
      result &= &"{pfx}  matches are decoded as: {d.decoded[0].unsafe_get}\n"
  of ddkRegexesMatch:
    result &= &"\n{pfx}  the regular expressions are:\n"
    for i, element in d.regexes_raw:
      result &= &"{pfx}   [{i}] => '{element}'\n"
    for i, element in d.decoded:
      if element.is_some:
        result &= &"{pfx}    matches to {d.regexes_raw[i]}\n"
        result &= &"{pfx}      are decoded as: {element.unsafe_get}\n"
  of ddkList:
    result &= &"\n{pfx}- validation:\n"
    result &= &"{pfx}  the list must contain between {d.lenrange.low} " &
              "and {d.lenrange.high} elements\n"
    result &= &"\n{pfx}- the type of list elements is:\n" &
              d.members_def.verbose_desc(indent+2)
  of ddkStruct:
    result &= &"\n{pfx}  the tuple contains {len(d.members)} elements\n"
    if d.n_required == len(d.members):
      result &= &"{pfx}  all elements of the tuple must be present\n"
    else:
      result &= &"{pfx}  of these, the first {d.n_required} " &
                "must be present, the remaining are optional\n"
    result &= &"\n{pfx}  the elements of the tuple are, in this order:\n"
    var i = 1
    for (k, v) in d.members:
      result &= &"\n{pfx}  - [{i}] element '{k}', defined as:\n" &
                v.verbose_desc(indent+4)
      i += 1
  of ddkDict:
    result &= &"\n{pfx}  thereby the key is one of the following " &
              &"{len(d.dict_members)} keys:\n"
    var i = 1
    for k, v in d.dict_members:
      result &= &"\n{pfx}  - [{i}] key '{k}', for which the value has " &
               "the following type:\n" & v.verbose_desc(indent+4)
      i += 1
    if len(d.required_keys) > 0 or len(d.single_keys) > 0:
      result &= &"\n{pfx}- validation:\n"
      if len(d.required_keys) > 0:
        result &= &"{pfx}    the following keys must always be present: " &
                  d.required_keys.join(", ") & "\n"
      if len(d.single_keys) > 0:
        result &= &"{pfx}    the following keys can only be present once: " &
                  d.single_keys.join(", ") & "\n"
  of ddkTags:
    result &= &"\n{pfx}  thereby the tag name matches the " &
                "regex '{d.tagname_regex_raw}'\n"
    result &= &"{pfx}  and the type code is one of the following:\n"
    for tagtype, valuedef in d.tagtypes:
      result &= &"\n{pfx}  - type code '{tagtype}', " &
                 "for values with type:\n" &
                 valuedef.verbose_desc(indent+4)
    if len(d.predefined_tags) > 0:
      result &= &"\n{pfx}- predefined tags\n" &
                &"{pfx}    the following tags, when " &
                 "present, must have the specified type:\n" &
                 &"{pfx}    {d.predefined_tags}\n"
  of ddkUnion:
    result &= &"\n{pfx}  there are {len(d.choices)} possible datatypes\n"
    if d.wrapped:
      result &= &"\n{pfx}- decoded value:\n"
      result &= &"{pfx}  the decoded data is a mapping which contains the " &
                  "two keys 'type' and 'value'\n" &
                &"{pfx}  'type' indicates which " &
                  "of the possible datatypes is used by the 'value' and is " &
                  "one of the following: {d.branch_names}\n"
    result &= &"{pfx}  the possible datatypes are:\n"
    for i, c in d.choices:
      result &= &"\n{pfx}  - datatype '<{i}>' defined as\n" &
        c.verbose_desc(indent+4)
  of ddkAnyInteger, ddkAnyUInteger, ddkAnyFloat, ddkAnyString, ddkJson:
    discard
  if d.encoded.is_some:
    let etab = d.encoded.unsafe_get
    result &= &"{pfx}- encoding rules:\n"
    for k, v in etab:
      result &= &"{pfx}    {k} is encoded as {v}\n"
  if len(d.implicit) > 0:
    result &= &"{pfx}- implicit values:\n" &
              &"{pfx}  the following key/value pairs are " &
               "additionally included in the decoded value:\n"
    for (k, v) in d.implicit:
      result &= &"{pfx}    {k} => {v}\n"
  if d.kind == ddkList or d.kind == ddkStruct or
     d.kind == ddkDict or d.kind == ddkTags:
    result &= &"\n{pfx}- formatting:\n"
    if len(d.pfx) > 0:
      result &= &"{pfx}    before the first element is the prefix '{d.pfx}'\n"
    if len(d.sfx) > 0:
      result &= &"{pfx}    after the last element is the suffix '{d.sfx}'\n"
    if len(d.sep) > 0:
      if d.sep == "\t":
        result &= &"{pfx}    the elements are separated by tabs\n"
      elif d.sep == "\n":
        result &= &"{pfx}    the elements are separated by newlines\n"
      else:
        result &= &"{pfx}    the elements are separated by '{d.sep}'\n"
      result &= &"{pfx}    (which "
      if d.sep_excl: result &= &"is never found "
      else:          result &= &"may also be present "
      result &= "in the elements text,\n"
      result &= &"{pfx}    thus "
      if d.sep_excl: result &= &"can "
      else:          result &= &"shall not "
      result &= "be used for splitting the string into elements)\n"
    else:
      result &= &"{pfx}    the elements are justapoxed, without any separator\n"
    if d.kind == ddkTags:
      if d.tags_internal_sep == "\t":
        result &= &"{pfx}    the name, type code and value are separated by " &
                             &"'{d.tags_internal_sep}'\n"
      elif d.tags_internal_sep == "\n":
        result &= &"{pfx}    the name, type code and value are separated by " &
                             &"'{d.tags_internal_sep}'\n"
      else:
        result &= &"{pfx}    the name, type code and value are separated by " &
                             &"'{d.tags_internal_sep}'\n"
      result &= &"{pfx}    (which can be present in the value, but not in " &
                           "the name or type code)\n"
    elif d.kind == ddkDict:
      if d.dict_internal_sep == "\t":
        result &= &"{pfx}    the key and the value are separated by tabs\n"
      elif d.dict_internal_sep == "\n":
        result &= &"{pfx}    the key and the value are separated by newlines\n"
      else:
        result &= &"{pfx}    the key and the value are separated by " &
                  &"'{d.dict_internal_sep}'\n"
      result &= &"{pfx}    (which can be present in the value, but not in " &
                           "the key)\n"
  if d.as_string:
    result &= &"\n{pfx}- decoded value:\n" &
              &"{pfx}    the datatype definition is " &
                         "only used for validation\n" &
              &"{pfx}    and not for parsing, i.e. the decoded " &
                      "data is a string\n" &
              &"{pfx}    (identical to the encoded data)\n"
  if d.kind != ddkRef:
    if d.null_value.is_some:
      result &= &"\n{pfx}- default decoded value:\n"
      result &= &"{pfx}  the encoded string may be empty\n"
      result &= &"{pfx}  which is decoded as: " &
                $((d.null_value).unsafe_get) & "\n"
    if d.kind != ddkRegexMatch:
      if len(d.regex.raw) > 0:
        result &= &"\n{pfx}- regular expression:\n"
        result &= &"{pfx}    regex which has been generated for the data type:\n"
        result &= &"{pfx}      '{d.regex.raw}'\n"
        result &= &"{pfx}    a match "
        if d.regex.ensures_valid:
          result &= "ensures "
        else:
          result &= "does not ensure "
        result &= &"validity of the encoded string\n"
        if not d.regex.ensures_valid:
          result &= &"{pfx}    (i.e. further operation are performed to " &
                 "ensure validity)\n"
  if d.scope != ddsUndef:
    result &= &"\n{pfx}Scope of the definition:\n"
    result &= &"{pfx}  {describe(d.scope)}\n"
    if d.scope == ddsUnit:
      result &= &"{pfx}  each unit consists of {d.unitsize} lines\n"

# TODO: use constants from def_syntax.nim
proc repr_desc*(d: DatatypeDefinition, indent: int): string =
  var
    pfx=" ".repeat(indent)
    idt = indent
  if d.is_nil:
    return "{pfx}null\n"
  if indent == 0:
    result &= &"{pfx}{d.name}:"
    if d.kind == ddkRef:
      result &= &" {d.target_name}\n"
      return result
    else:
      result &= "\n"
      idt = 2
      pfx = "  "
  case d.kind:
  of ddkRef:
    return &"{pfx}{d.target_name}\n"
  of ddkAnyInteger:
    return &"{pfx}integer\n"
  of ddkAnyUInteger:
    return &"{pfx}unsigned_integer\n"
  of ddkAnyFloat:
    return &"{pfx}float\n"
  of ddkAnyString:
    return &"{pfx}string\n"
  of ddkJson:
    return &"{pfx}json\n"
  of ddkIntRange:
    result &= &"{pfx}integer: {{"
    let
      l = d.range_i.lowstr
      h = d.range_i.highstr
    var l_added = false
    if l != "-Inf":
      result &= &"min: {l}"
      l_added = true
    if h != "Inf":
      if l_added:
        result &= ", "
      result &= &"max: {h}"
    result &= "}\n"
  of ddkUIntRange:
    result &= &"{pfx}unsigned_integer: {{"
    let
      l = d.range_u.lowstr
      h = d.range_u.highstr
    var l_added = false
    if l != "0":
      result &= &"min: {l}"
      l_added = true
    if h != "Inf":
      if l_added:
        result &= ", "
      result &= &"max: {h}"
    result &= "}\n"
  of ddkFloatRange:
    result &= &"{pfx}float: {{"
    let
      l = d.range_i.lowstr
      h = d.range_i.highstr
    var any_added = false
    if l != "-Inf":
      result &= &"min: {l}"
      any_added = true
    if h != "Inf":
      if any_added:
        result &= ", "
      result &= &"max: {h}"
      any_added = true
    if not d.min_incl:
      if any_added:
        result &= ", "
      result &= "min_excluded: true"
      any_added = true
    if not d.max_incl:
      if any_added:
        result &= ", "
      result &= "max_excluded: true"
    result &= "}\n"
  of ddkRegexMatch:
    result &= &"{pfx}regex:"
    if d.decoded[0].is_some:
      result &= &"{{{%d.regex.raw}: {d.decoded[0].unsafe_get}}}"
    else:
      result &= &"{%d.regex.raw}\n"
  of ddkRegexesMatch:
    result &= &"{pfx}regexes: ["
    for i, element in d.decoded:
      if i > 0:
        result &= ", "
      if element.is_some:
        result &= &"{%d.regexes_raw[i]}: {element.unsafe_get}"
      else:
        result &= &"{%d.regexes_raw[i]}"
    result &= "]\n"
  of ddkConst:
    result &= &"{pfx}constant: "
    if d.decoded[0].is_some:
      result &= &"{{{d.constant_element.to_json}: {d.decoded[0].unsafe_get}}}\n"
    else:
      result &= &"{d.constant_element.to_json}\n"
  of ddkEnum:
    result &= &"{pfx}accepted_values: ["
    for i, element in d.elements:
      if i > 0:
        result &= ", "
      result &= d.elements[i].to_json
      if d.decoded[i].is_some:
        result &= &": {d.decoded[i].unsafe_get}"
    result &= "]\n"
  of ddkList:
    result &= &"{pfx}list_of:"
    if d.members_def.kind == ddkRef:
      result &= &" {d.members_def.target_name}\n"
    else:
      result &= &"\n{d.members_def.repr_desc(idt+2)}"
  of ddkStruct:
    result &= &"{pfx}composed_of:\n"
    for (k, v) in d.members:
      result &= &"{pfx}- {k}:"
      if v.kind == ddkRef:
        result &= &" {v.target_name}\n"
      else:
        result &= &"\n{v.repr_desc(idt+2)}"
    if d.n_required != len(d.members):
      result &= &"n_required: {d.n_required}\n"
  of ddkDict:
    result &= &"{pfx}named_values:\n"
    for k, v in d.dict_members:
      result &= &"\n{k}: "
      if v.kind == ddkRef:
        result &= &" {v.target_name}\n"
      else:
        result &= &"\n{v.repr_desc(idt+2)}"
    if len(d.required_keys) > 0:
      result &= &"{pfx}required: [" &
                d.required_keys.join(", ") & "]\n"
    if len(d.single_keys) > 0:
      result &= &"{pfx}single: [" &
                d.single_keys.join(", ") & "]\n"
  of ddkTags:
    result &= &"{pfx}tagged_values:\n"
    for k, v in d.tagtypes:
      result &= &"\n{k}: "
      if v.kind == ddkRef:
        result &= &" {v.target_name}\n"
      else:
        result &= &"\n{v.repr_desc(idt+2)}"
    result &= &"{pfx}tagnames: {%d.tagname_regex_raw}\n"
    if len(d.predefined_tags) > 0:
      result &= &"{pfx}predefined: {%(d.predefined_tags)}\n"
  of ddkUnion:
    result &= &"{pfx}one_of:\n"
    for i, c in d.choices:
      result &= &"{pfx}- {c.repr_desc(idt+2)}"
    if d.wrapped:
      result &= &"{pfx}wrapped: true\n"
    result &= &"{pfx}branch_names: {%d.branch_names}\n"
  if d.encoded.is_some:
    let etab = d.encoded.unsafe_get
    result &= &"{pfx}canonical: {{\n"
    var any_added = false
    for k, v in etab:
      if any_added:
        result &= ", "
      result &= &"{v}: {k}"
      any_added = true
    result &= "}\n"
  if len(d.implicit) > 0:
    result &= &"{pfx}implicit: {{"
    var any_added = false
    for (k, v) in d.implicit:
      if any_added:
        result &= ", "
      result &= &"{k}: {v}"
      any_added = true
    result &= "}\n"
  if len(d.pfx) > 0:
    result &= &"{pfx}prefix: {%d.pfx}\n"
  if len(d.sfx) > 0:
    result &= &"{pfx}suffix: {%d.sfx}\n"
  if len(d.sep) > 0:
    if d.sep_excl:
      result &= &"{pfx}splitted_by: {%d.sep}\n"
    else:
      result &= &"{pfx}separator: {%d.sep}\n"
  if d.kind == ddkTags:
    result &= &"{pfx}internal_separator: {%d.tags_internal_sep}\n"
  elif d.kind == ddkDict:
    result &= &"{pfx}internal_separator: {%d.dict_internal_sep}\n"
  if d.as_string:
    result &= &"{pfx}as_string: true\n"
  if d.null_value.is_some:
    result &= &"{pfx}empty: {d.null_value.unsafe_get}\n"
  if d.scope != ddsUndef:
    result &= &"{pfx}scope: {d.scope}\n"
  if d.unitsize > 1:
    result &= &"{pfx}unitsize: {d.unitsize}\n"

proc tabular_desc*(d: DatatypeDefinition, indent: int): string =
  let pfx=" ".repeat(indent)
  if d.is_nil:
    return &"{pfx}(nil)"
  if indent == 0:
    result &=  &"{pfx}Datatype definition:\n"
  result &= &"{pfx}- name: {d.name}\n"
  result &= &"{pfx}- kind: {d.kind}\n"
  if d.kind != ddkRef:
    result &= &"{pfx}- regex: "
    if d.regex_computed:
      result &= &"'{d.regex.raw}' (ensures_valid:"
      if d.regex.ensures_valid:
        result &= "y)"
      else:
        result &= "n)"
    else:
      result &= "-"
    result &= "\n"
    if d.null_value.is_some:
      result &= &"{pfx}- null_value: '"
      result &= $((d.null_value).unsafe_get)
      result &= "'\n"
    else:
      result &= &"{pfx}- null_value: -\n"
  if d.kind == ddkList or d.kind == ddkStruct or
     d.kind == ddkDict or d.kind == ddkTags:
    result &= &"{pfx}- prefix: '{d.pfx}'\n"
    if d.sep_excl:
      result &= &"{pfx}- splitted_by: {d.sep_excl}\n"
    else:
      result &= &"{pfx}- separator: '{d.sep}'\n"
    result &= &"{pfx}- suffix: '{d.sfx}'\n"
  case d.kind:
  of ddkRef:
    if d.has_unresolved_ref:
      result &= &"{pfx}- target: <{d.target_name}>\n"
    else:
      assert not d.target.is_nil
      result &= &"{pfx}- target:"
      if d.target_name.len > 0:
        result &= &" ('{d.target_name}')"
      else:
        result &= " (anonymous)"
      result &= "\n" & d.target.tabular_desc(indent+2)
  of ddkIntRange:
    result &= &"{pfx}- range: {d.range_i}\n"
  of ddkUIntRange:
    result &= &"{pfx}- range: {d.range_u}\n"
    result &= &"{pfx}- base: {d.base}\n"
  of ddkFloatRange:
    result &= &"{pfx}- range: ({d.min_incl},{d.min_f},{d.max_f},{d.max_incl})\n"
  of ddkConst:
    result &= &"{pfx}- constant_element: {d.constant_element}\n"
    result &= &"{pfx}- decoded: {d.decoded[0]}\n"
  of ddkEnum:
    result &= &"{pfx}- elements: {d.elements}\n"
    result &= &"{pfx}- decoded: {d.decoded}\n"
    result &= &"{pfx}- encoded: {d.encoded}\n"
  of ddkRegexMatch:
    result &= &"{pfx}- regex: (see above)\n"
    result &= &"{pfx}- decoded: {d.decoded[0]}\n"
    result &= &"{pfx}- encoded: {d.encoded}\n"
  of ddkRegexesMatch:
    result &= &"{pfx}- regexes: {d.regexes_raw}\n"
    result &= &"{pfx}- decoded: {d.decoded}\n"
    result &= &"{pfx}- encoded: {d.encoded}\n"
  of ddkList:
    result &= &"{pfx}- lenrange: {d.lenrange}\n"
    result &= &"{pfx}- members_def:\n" & d.members_def.tabular_desc(indent+2)
  of ddkStruct:
    result &= &"{pfx}- members:\n"
    for (k, v) in d.members:
      result &= &"{pfx}  - {k}:\n" & v.tabular_desc(indent+4)
    result &= &"{pfx}- n_required: {d.n_required}\n"
  of ddkDict:
    result &= &"{pfx}- members:\n"
    for k, v in d.dict_members:
      result &= &"{pfx}  - {k}:\n" & v.tabular_desc(indent+4)
    result &= &"{pfx}- required: {d.required_keys}\n"
    result &= &"{pfx}- single: {d.single_keys}\n"
    result &= &"{pfx}- internal sep: '{d.dict_internal_sep}'\n"
  of ddkTags:
    result &= &"{pfx}- name regex: {d.tagname_regex_raw}\n"
    result &= &"{pfx}- members:\n"
    for tagtype, valuedef in d.tagtypes:
      result &= &"{pfx}  - {tagtype}:\n" & valuedef.tabular_desc(indent+4)
    result &= &"{pfx}- predefined tags: {d.predefined_tags}\n"
    result &= &"{pfx}- internal sep: '{d.tags_internal_sep}'\n"
  of ddkUnion:
    result &= &"{pfx}- choices:\n"
    for i, c in d.choices:
      result &= &"{pfx}  - <{i}>:\n" & c.tabular_desc(indent+4)
    if d.wrapped:
      result &= &"{pfx}- wrapped; branch names: {d.branch_names}\n"
  of ddkAnyInteger, ddkAnyUInteger, ddkAnyFloat, ddkAnyString, ddkJson:
    discard
  if d.kind == ddkStruct or d.kind == ddkDict or d.kind == ddkTags:
    result &= &"{pfx}- implicit:"
    if len(d.implicit) > 0:
      result &= "\n"
      for (k, v) in d.implicit:
        result &= &"{pfx}  - {k}:{v}\n"
    else:
      result &= " []\n"
  if d.kind != ddkRef and d.kind != ddkAnyString and
     d.kind != ddkRegexMatch and d.kind != ddkRegexesMatch:
    result &= &"{pfx}- as_string: {d.as_string}\n"
  result &= &"{pfx}- scope: {d.scope}\n"
  if d.scope == ddsUnit:
    result &= &"{pfx}- unitsize: {d.unitsize}\n"
