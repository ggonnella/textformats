# standard library
import options
import tables
import strformat
import json
import strutils
import regex
import match_element
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
## - a sequence of a fixed number of named members,
##   each of them of possibly a different datatype (struct; ddkStruct)
## - a list of any length, where each element has
##   the same datatype (array; ddkList)
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

    # Kind-specific information

    case kind*: DatatypeDefinitionKind
    of ddkJson,
       ddkAnyInteger, ddkAnyUInteger,
       ddkAnyFloat, ddkAnyString, ddkRegexMatch: discard

    of ddkRef:
      target*: DatatypeDefinition
      target_name*: string

    of ddkIntRange:
      range_i*: OpenRange[int]

    of ddkUIntRange:
      range_u*: OpenRange[uint]

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
      type_labels*: seq[string]

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

proc tabular_desc(d: DatatypeDefinition, indent: int): string

proc `$`*(dd: DatatypeDefinition): string =
  dd.tabular_desc(0)

proc tabular_desc(d: DatatypeDefinition, indent: int): string =
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
    result &= &"{pfx}- pfx: '{d.pfx}'\n"
    result &= &"{pfx}- sep: '{d.sep}'\n"
    result &= &"{pfx}- split_by_sep: {d.sep_excl}\n"
    result &= &"{pfx}- sfx: '{d.sfx}'\n"
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
      result &= &"{pfx}- wrapped; type labels {d.type_labels}\n"
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
