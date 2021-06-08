import json
import sequtils
import strformat
import strutils
import tables
import sets
import regex
import ../types / [datatype_definition, textformats_error]
import ../support/json_support
import ../encoder

proc tags_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_object:
    raise newException(EncodingError,
                      "Error: value is not a dictionary\n" &
                      value.describe_kind & "\n")
  var i = 0
  result = dd.pfx
  var implicit = newTable[string, JsonNode]()
  for (name, v) in dd.implicit:
    implicit[name] = v
  for tagname, type_value in value:
    if tagname in implicit:
      if type_value != implicit[tagname]:
        raise newException(EncodingError,
                           "Error: invalid value for implicit key\n" &
                           &"Implicit key: {tagname}\n" &
                           &"Expected value: '{implicit[tagname]}'\n" &
                           &"Found: '{type_value}'\n")
    else:
      if not tagname.match(dd.tagname_regex_compiled):
        raise newException(EncodingError,
          "Error: tagname does not match the specified regular expression\n" &
          &"Tagname: {tagname}\n" &
          "Regular expression: " & dd.tagname_regex_raw & "\n" &
          &"Partial encoded string (before error): {result}\n")
      if not type_value.is_object:
        raise newException(EncodingError,
          "Error: item is not a dictionary\n" &
          &"Tagname: {tagname}\n" &
          "Kind of item: " & type_value.describe_kind & "\n" &
          &"Expected: dictionary with the keys: {dd.typekey}, {dd.valuekey}\n" &
          &"Partial encoded string (before error): {result}\n")
      var typevalue_keys = to_seq(type_value.get_fields.keys).to_hash_set
      if dd.typekey notin typevalue_keys:
        raise newException(EncodingError,
          "Error: missing key in item dictionary\n" &
          &"Tagname: {tagname}\n" &
          &"Missing key: {dd.typekey}\n" &
          &"Expected: dictionary with the keys: {dd.typekey}, {dd.valuekey}\n" &
          &"Partial encoded string (before error): {result}\n")
      typevalue_keys.excl(dd.typekey)
      if dd.valuekey notin typevalue_keys:
        raise newException(EncodingError,
          "Error: missing key in item dictionary\n" &
          &"Tagname: {tagname}\n" &
          &"Missing key: {dd.valuekey}\n" &
          &"Expected: dictionary with the keys: {dd.typekey}, {dd.valuekey}\n" &
          &"Partial encoded string (before error): {result}\n")
      typevalue_keys.excl(dd.valuekey)
      if len(typevalue_keys) > 0:
        raise newException(EncodingError,
          "Error: invalid keys in item dictionary\n" &
          &"Tagname: {tagname}\n" &
          &"Invalid keys: {typevalue_keys}\n" &
          &"Expected: dictionary with the keys: {dd.typekey}, {dd.valuekey}\n" &
          &"Partial encoded string (before error): {result}\n")
      let typetag = typevalue[dd.typekey]
      if tagname in dd.predefined_tags and
          dd.predefined_tags[tagname] != typetag:
        raise newException(EncodingError,
          "Error: wrong type for predefined tag\n" &
          &"Tagname: {tagname}\n" &
          &"Expected type: {dd.predefined_tags[tagname]}\n" &
          &"Found type: {typetag}\n" &
          &"Partial encoded string (before error): {result}\n")
      if typetag notin dd.tagtypes:
        raise newException(EncodingError,
          "Error: unknown type for tag\n" &
          &"Tagname: {tagname}\n" &
          &"Known types: " & to_seq(dd.tagtypes.keys).join(", ") & "\n" &
          &"Found type: {typetag}\n" &
          &"Partial encoded string (before error): {result}\n")
      var tagvalue_str: string
      let tagvalue = typevalue[dd.valuekey]
      try:
        tagvalue_str = tagvalue.encode(dd.tagtypes[typetag])
      except EncodingError:
        raise newException(EncodingError,
          "Error: invalid value for tag\n" &
          &"Tagname: {tagname}\n" &
          &"Partial encoded string (before error): {result}\n" &
          get_current_exception_msg().indent(2))
      if i > 0: result &= dd.sep
      result &= tagname & dd.tags_internal_sep & typetag &
        dd.tags_internal_sep & tagvalue_str
      i += 1
  result &= dd.sfx

proc tags_unsafe_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  var i = 0
  result = dd.pfx
  var implicit = newTable[string, JsonNode]()
  for (name, v) in dd.implicit:
    implicit[name] = v
  for tagname, type_value in value:
    if tagname notin implicit:
      let tagvalue_str =
        typevalue[dd.valuekey].encode(dd.tagtypes[typevalue[dd.typekey]])
      if i > 0: result &= dd.sep
      result &= tagname & dd.tags_internal_sep &
                typevalue[dd.typekey] & dd.tags_internal_sep & tagvalue_str
      i += 1
  result &= dd.sfx

