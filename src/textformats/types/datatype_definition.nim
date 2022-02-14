# standard library
import options, tables, strformat, json
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
    constant_pfx*: string

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
      branch_pfx*: seq[string]
      branch_pfx_ensure*: bool

    # Construction flags

    has_unresolved_ref*: bool
    regex_computed*: bool

proc children*(dd: DatatypeDefinition): seq[DatatypeDefinition] =
  result = newseq[DatatypeDefinition]()
  case dd.kind:
  of ddkRef:
    if not dd.target.isNil:
      result.add(dd.target)
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

proc parse_scope*(scope: string): DatatypeDefinitionScope =
  let valid_definition_types = @["file", "section", "unit", "line"]
  if scope notin valid_definition_types:
    let scope_errmsg = block:
      var msg = "Error: scope must be one of the following values:\n"
      for t in valid_definition_types:
        msg &= &"- {t}\n"
      msg
    raise newException(TextFormatsRuntimeError, scope_errmsg)
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
    raise newException(TextFormatsRuntimeError,
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

