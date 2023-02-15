import sequtils, tables, strformat, strutils, sets, json
import ../types / [datatype_definition, textformats_error]
import ../support/json_support
import ../shared/implicit_encoder
import ../encoder
import struct_nesting

template format_results(results: seq[string], dd: DatatypeDefinition): string =
  dd.pfx & results.join(dd.sep) & dd.sfx

proc reraise_invalid_element(name: string, results: seq[string],
                             dd: DatatypeDefinition) =
  let
    before = results.format_results(dd)
    e = getCurrentException()
  e.msg = &"Invalid value for structure element '{name};:\n" & e.msg.indent(2)
  if len(before) > 0:
    e.msg = "After encoding: '{before}'\n" & e.msg
  raise

proc raise_required_key_missing(name: string, i: int, results: seq[string],
                                dd: DatatypeDefinition) =
  let
    before = results.format_results(dd)
    e = newException(EncodingError, &"Missing required dict.key '{name}'\n")
  if len(before) > 0:
    e.msg = "After encoding: '{before}'\n" & e.msg
  raise e

proc raise_optional_key_missing(name: string, optname: string,
                                results: seq[string], dd: DatatypeDefinition) =
  let
    before = results.format_results(dd)
    e = newException(EncodingError,
          &"Missing dict.key '{name}', required since '{optname}' is present\n")
  if len(before) > 0:
    e.msg = "After encoding: '{before}'\n" & e.msg
  raise e

template try_encoding(element: JsonNode, namemsg: string,
                      subdef: DatatypeDefinition,
                      dd: DatatypeDefinition, results: var seq[string]) =
  try:
    results.add(element.encode(subdef))
  except EncodingError:
    reraise_invalid_element(namemsg, results, dd)

proc struct_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_object:
    raise newException(EncodingError, "Value is not a dictionary, found: " &
            value.describe_kind & "\n")
  var
    nvalue = if dd.combine_nested: value.normalize_struct_values()
             else: value
    value_keys = to_seq(nvalue.get_fields.keys).to_hash_set
    results = newseq_of_cap[string](dd.members.len)
    i = 0
  for (name, subdef) in dd.members:
    if i in dd.hidden:
      results.add(subdef.constant_element.s_value)
    else:
      if name notin value_keys:
        if i < dd.n_required:
          raise_required_key_missing(name, i, results, dd)
        else:
          for j in i..<dd.members.len:
            let optname = dd.members[j].name
            if optname in value_keys:
              raise_optional_key_missing(name, optname, results, dd)
          break
      try_encoding(nvalue[name], name, subdef, dd, results)
    value_keys.excl(name)
    i+=1
  nvalue.validate_nonmember_keys(value_keys, dd)
  return results.format_results(dd)

proc struct_unsafe_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  var
    results = newseq_of_cap[string](dd.members.len)
    i = 0
  for (name, subdef) in dd.members:
    if i in dd.hidden:
      results.add(subdef.constant_element.s_value)
    else:
      results.add(value[name].unsafe_encode(subdef))
    i+=1
  return results.format_results(dd)

