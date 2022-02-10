import json, strformat, strutils, tables, sets
import ../types / [datatype_definition, textformats_error]
import ../decoder
import ../shared/formatting_decoder

proc decode_value*(value_str: string, dd: DatatypeDefinition,
                  key: string): JsonNode {.inline.} =
  let value_def = dd.dict_members[key]
  try:
    result = value_str.decode(value_def)
  except DecodingError:
    let e = getCurrentException()
    e.msg = &"Invalid value for key '{key}'\n" & e.msg.indent(2)
    raise

template validate_required*(fields, dd: untyped) =
  for key in dd.dict_members.keys:
    if key in dd.required_keys and key notin fields:
      raise newException(DecodingError, "Error: missing key '" & key & "'\n")

template parse_and_validate_element*(elem, dd, previous_keys: untyped):
                                    (string, string) =
  let components = elem.split(dd.dict_internal_sep, max_split=1)
  if components.len < 2:
    raise newException(DecodingError,
                       "Internal separator (key/value) not found\n")
  let
    key = components[0]
    value_str = components[1]
  if key notin dd.dict_members:
    raise newException(DecodingError, "Unknown key '" & key & "'\n")
  if key in dd.single_keys and key in previous_keys:
    raise newException(DecodingError, "Key '" & key & "' is repeated\n")
  (key, value_str)

template decode_element*(elem, dd, fields: untyped) =
  let (key, value_str) = parse_and_validate_element(elem, dd, fields)
  if key notin dd.single_keys and key notin fields:
    fields[key] = newJArray()
  let value = value_str.decode_value(dd, key)
  if key in dd.single_keys: fields[key] = value
  else:                     fields[key].add(value)

proc decode_dict*(input: string, dd: DatatypeDefinition): JsonNode =
  assert dd.kind == ddkDict
  result = newJObject()
  let core = validate_and_remove_pfx_and_sfx(input, dd,
               emsg_pfx = "Wrong formatting of encoded string.\n")
  for elem in core.split(dd.sep):
    elem.decode_element(dd, result.fields)
  result.fields.validate_required(dd)
  for (k, v) in dd.implicit: result.fields[k] = v

