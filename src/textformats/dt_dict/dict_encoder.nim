import json, sets, strformat, strutils, sequtils, tables
import ../types / [datatype_definition, textformats_error]
import ../support/json_support
import ../shared/implicit_encoder
import ../encoder

proc encode_element(element: JsonNode, name: string, internal_sep: string,
                    subdef: DatatypeDefinition): string {.inline.} =
  result = name & internal_sep
  try:
    result &= element.encode(subdef)
  except EncodingError:
    let e = get_current_exception()
    raise newException(EncodingError,
      "Error: invalid dictionary value\n" &
      &"Key of invalid value: {name}\n" & e.msg.indent(2))

proc dict_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_object:
    raise newException(EncodingError,
            "Error: value is not a dictionary\n" &
            value.describe_kind & "\n")
  var
    value_keys = to_seq(value.get_fields.keys).to_hash_set
    i = 0
  result = dd.pfx
  for name, def in dd.dict_members:
    if name notin value_keys and name in dd.required_keys:
      raise newException(EncodingError,
              "Error: dictionary does not contain a required key\n" &
              &"Missing required key: '{name}'\n")
    else:
      if name in dd.single_keys:
        if i > 0:
          result &= dd.sep
        result &= value[name].encode_element(name, dd.dict_internal_sep, def)
        i += 1
      else:
        for subvalue in value[name]:
          if i > 0:
            result &= dd.sep
          result &= subvalue.encode_element(name, dd.dict_internal_sep, def)
          i += 1
    value_keys.excl(name)
  value.validate_nonmember_keys(value_keys, dd)
  result &= dd.sfx

proc unsafe_encode_element(element: JsonNode, name: string,
                           internal_sep: string, subdef: DatatypeDefinition):
                             string {.inline.} =
  name & internal_sep & element.encode(subdef)

proc dict_unsafe_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  var i = 0
  result = dd.pfx
  for name, def in dd.dict_members:
    if name in dd.single_keys:
      if i > 0: result &= dd.sep
      result &=
        value[name].unsafe_encode_element(name, dd.dict_internal_sep, def)
      i += 1
    else:
      for subvalue in value[name]:
        if i > 0: result &= dd.sep
        result &=
          subvalue.unsafe_encode_element(name, dd.dict_internal_sep, def)
        i += 1
  result &= dd.sfx
