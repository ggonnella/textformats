import sequtils, tables, strformat, strutils, sets, json
import ../types / [datatype_definition, textformats_error]
import ../support/json_support
import ../shared/implicit_encoder
import ../encoder

template format_results(results: seq[string], dd: DatatypeDefinition): string =
  dd.pfx & results.join(dd.sep) & dd.sfx

proc raise_invalid_element(name: string, results: seq[string],
                           errmsg: string, dd: DatatypeDefinition) =
  raise newException(EncodingError,
          "Error: invalid value for structure element\n" &
          &"Key of invalid element: {name}\n" &
          "Partial encoded string " &
          &"(before invalid element): {results.format_results(dd)}\n" &
          "Error while encoding value:\n" & errmsg.indent(2))

proc raise_required_key_missing(name: string, i: int, results: seq[string],
                                dd: DatatypeDefinition) =
  raise newException(EncodingError,
          "Error: required dictionary key missing\n" &
          &"Number of keys found: {i+1}\n"&
          &"Number of required keys: {dd.n_required}\n"&
          "Partial encoded string " &
          &"(before missing value): {results.format_results(dd)}\n" &
          &"Missing key: {name}\n")

proc raise_optional_key_missing(name: string, optname: string,
                                results: seq[string], dd: DatatypeDefinition) =
  raise newException(EncodingError,
          "Error: required dictionary key missing\n" &
          &"Optional key '{optname}' is present, requiring all optional "&
            "keys before it to be present as well\n" &
          "Partial encoded string " &
          &"(before missing value): {results.format_results(dd)}\n" &
          &"Missing key: {name}\n")

template try_encoding(element: JsonNode, namemsg: string,
                      subdef: DatatypeDefinition,
                      dd: DatatypeDefinition, results: var seq[string]) =
  try:
    results.add(element.encode(subdef))
  except EncodingError:
    let e = get_current_exception()
    raise_invalid_element(namemsg, results, e.msg, dd)

proc struct_encode*(value: JsonNode, dd: DatatypeDefinition): string =
  if not value.is_object:
    raise newException(EncodingError, "Error: value is not a dictionary\n" &
            value.describe_kind & "\n")
  var
    value_keys = to_seq(value.get_fields.keys).to_hash_set
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
      try_encoding(value[name], name, subdef, dd, results)
    value_keys.excl(name)
    i+=1
  value.validate_nonmember_keys(value_keys, dd)
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

