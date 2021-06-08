import json, sets, strformat, strutils, tables
import regex
import ../types / [datatype_definition, textformats_error]
import ../support/json_support
import ../shared/formatting_decoder
import ../decoder

proc validate_tagname_format(tagname: string,
                             dd: DatatypeDefinition) {.inline.} =
  if not tagname.match(dd.tagname_regex_compiled):
    raise newException(DecodingError,
                    "Error: tag name does not match regular expression\n" &
                    &"Regular expression: {dd.tagname_regex_raw}\n" &
                    &"Tag name: '{tagname}'\n")

proc validate_tagname_unique(tagname: string,
                              found_tagnames: var HashSet[string]) {.inline.} =
  if tagname in found_tagnames:
    raise newException(DecodingError,
                       "Error: multiple instances of tag found\n" &
                       &"Tag name: '{tagname}'\n")
  found_tagnames.incl(tagname)

proc validate_if_predefined(tagname: string, tagtype: string,
                         dd: DatatypeDefinition) {.inline.} =
  if tagname in dd.predefined_tags:
    let expectedtype = dd.predefined_tags[tagname]
    if expectedtype != tagtype:
      raise newException(DecodingError,
                         "Error: wrong type for predefined tag\n" &
                         &"Tag name: '{tagname}'\n" &
                         &"Required tag type: {expectedtype}\n" &
                         &"Found tag type: {tagtype}\n")

proc validate_not_implicit(tagname: string, dd: DatatypeDefinition)
                           {.inline.} =
  for implicit in dd.implicit:
    if implicit.name == tagname:
      raise newException(DecodingError,
                         "Error: tag name is equal to an implicit tag name\n" &
                         &"Implicit tag name: {implicit.name}\n" &
                         &"Implicitly defined as: {implicit.value}\n")

proc decode_value(value_str: string, value_def: DatatypeDefinition,
                  tagname: string): JsonNode {.inline.} =
  try:
    result = value_str.decode(value_def)
  except DecodingError:
    raise newException(DecodingError,
                    "Error: invalid encoded value for tag\n" &
                    &"Tag name: {tagname}\n" &
                    get_current_exception_msg().indent(2))

proc decode_tags*(input: string, dd: DatatypeDefinition): JsonNode =
  assert dd.kind == ddkTags
  var
    elements = newseq[(string, JsonNode)]()
    found_tagnames: HashSet[string]
  let core = validate_and_remove_pfx_and_sfx(input, dd,
               emsg_pfx = "Error: wrong encoded string format\n")
  for elem in core.split(dd.sep):
    let components = elem.split(dd.tags_internal_sep, max_split=2)
    if components.len == 1:
      raise newException(DecodingError,
              "Error: Internal name/type/value separator not found\n")
    elif components.len == 2:
      raise newException(DecodingError,
              "Error: Internal name/type/value separator found only once\n" &
              "Expected: separator should be present at least twince\n" &
              "(between: (1) name and type; (2) type and value)\n")
    let
      tagtype = components[1]
      tagname = components[0]
      value = components[2].decode_value(dd.tagtypes[tagtype], tagname)
    tagname.validate_tagname_format(dd)
    tagname.validate_tagname_unique(found_tagnames)
    tagname.validate_if_predefined(tagtype, dd)
    tagname.validate_not_implicit(dd)
    elements.add((tagname, %*{dd.typekey: tagtype, dd.valuekey: value}))
  if dd.implicit.len > 0:
    elements &= dd.implicit
  result = newJObject()
  result.fields = elements.to_ordered_table

