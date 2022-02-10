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
    raise newException(EncodingError, "Value is not a dictionary, found: " &
                      value.describe_kind & "\n")
  var i = 0
  result = dd.pfx
  var implicit = newTable[string, JsonNode]()
  for (name, v) in dd.implicit:
    implicit[name] = v
  for tagname, type_value in value:
    if tagname in implicit:
      if type_value != implicit[tagname]:
        raise newException(EncodingError, &"Invalid value '{type_value}' " &
                  &"for key '{tagname}', expected '{implicit[tagname]}'\n")
    else:
      if not tagname.match(dd.tagname_regex_compiled):
        raise newException(EncodingError,
          &"Tagname {tagname} not matching reg.expr.: " &
          dd.tagname_regex_raw & "\n" &
          &"Partial encoded string (before error): {result}\n")
      if not type_value.is_object:
        raise newException(EncodingError,
          &"Tag value '{tagname}' is not a dictionary, found: " &
          type_value.describe_kind & "\n" &
          &"Partial encoded string (before error): {result}\n")
      var typevalue_keys = to_seq(type_value.get_fields.keys).to_hash_set
      if dd.typekey notin typevalue_keys:
        raise newException(EncodingError,
          &"Missing key '{dd.typekey}' in tag dictionary '{tagname}'\n" &
          &"Partial encoded string (before error): {result}\n")
      typevalue_keys.excl(dd.typekey)
      if dd.valuekey notin typevalue_keys:
        raise newException(EncodingError,
          &"Missing key '{dd.valuekey}' in tag dictionary '{tagname}'\n" &
          &"Partial encoded string (before error): {result}\n")
      typevalue_keys.excl(dd.valuekey)
      if len(typevalue_keys) > 0:
        raise newException(EncodingError,
          &"Invalid keys {typevalue_keys}' in tag dictionary '{tagname}'\n" &
          &"Expected: {dd.typekey}, {dd.valuekey}\n" &
          &"Partial encoded string (before error): {result}\n")
      let typetag = typevalue[dd.typekey]
      if tagname in dd.predefined_tags and
          dd.predefined_tags[tagname] != typetag:
        raise newException(EncodingError,
          &"Tag '{tagname}', expected type: {dd.predefined_tags[tagname]}, " &
          &"found: {typetag}\n" &
          &"Partial encoded string (before error): {result}\n")
      if typetag notin dd.tagtypes:
        raise newException(EncodingError,
          &"Tag '{tagname}', unknown type: {typetag}, " &
          &"expected one of: \n" & to_seq(dd.tagtypes.keys).join(", ") & "\n" &
          &"Partial encoded string (before error): {result}\n")
      var tagvalue_str: string
      let tagvalue = typevalue[dd.valuekey]
      try:
        tagvalue_str = tagvalue.encode(dd.tagtypes[typetag])
      except EncodingError:
        let e = getCurrentException()
        e.msg = &"Tag '{tagname}', invalid value:\n" & e.msg.indent(2)
        if len(result) > 0:
          e.msg = &"Partial encoded string (before error): {result}\n" & e.msg
        raise
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

