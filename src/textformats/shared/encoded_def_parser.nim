import options, strformat, strutils, sequtils, json, tables
import yaml/dom
import regex
import ../support/yaml_support
import ../types / [def_syntax, textformats_error, match_element]

type
  ValidationInfoItemKind = enum
    viikRegex
    viikString
    viikInt
    viikFloat

  ValidationInfoItem = object
    case kind*: ValidationInfoItemKind
    of viikRegex: r_value: tuple[raw: string, compiled: Regex]
    of viikString: s_value: string
    of viikInt: i_value: int
    of viikFloat: f_value: float

  ValidationInfo* = TableRef[string,
    tuple[values: seq[ValidationInfoItem], found: bool]]

proc newValidationInfo*(): ValidationInfo =
  newTable[string, tuple[values: seq[ValidationInfoItem], found: bool]]()

proc add*(info: var ValidationInfo, key: string, raw: string) =
  if key notin info:
    info[key] = (values: newseq[ValidationInfoItem](), found: false)
  info[key].values.add(ValidationInfoItem(kind: viikRegex,
                  r_value: (raw: raw, compiled: raw.re)))

proc add*(info: var ValidationInfo, key: string, value: MatchElement) =
  if key notin info:
    info[key] = (values: newseq[ValidationInfoItem](), found: false)
  let item = block:
    case value.kind:
      of meFloat: ValidationInfoItem(kind: viikFloat, f_value: value.f_value)
      of meInt: ValidationInfoItem(kind: viikInt, i_value: value.i_value)
      of meString: ValidationInfoItem(kind: viikString, s_value: value.s_value)
  info[key].values.add(item)

proc rm_singletons*(info: var ValidationInfo) =
  var to_rm = newseq[string]()
  for k, v in info:
    if v.values.len == 1: to_rm.add(k)
  for k in to_rm: info.del(k)

const
  EncodedHelp* = "mapping of scalars (string, numeric, null, bool) to strings"

proc reqkeysmsg(validation_info: ValidationInfo): string =
  &"Required key(s) for '{EncodedKey}': " &
    to_seq(validation_info.keys).join(", ")

proc validate_vstr(vstr: string, infoitems: seq[ValidationInfoItem]) =
  var errmsg = ""
  for item in infoitems:
    case item.kind:
    of viikRegex:
      if vstr.match(item.r_value.compiled): return
      else: errmsg.add("- regex: {item.r_value.raw}\n")
    of viikString:
      if item.s_value == vstr: return
      else: errmsg.add("- string: {item.s_value}\n")
    of viikInt:
      if item.i_value == parse_int(vstr): return
      else: errmsg.add("- integer: {item.i_value}\n")
    of viikFloat:
      if item.f_value == parse_float(vstr): return
      else: errmsg.add("- float: {item.f_value}\n")
  raise newException(DefSyntaxError,
            &"'{EncodedKey}' mapping contains an invalid value\n" &
            &"Invalid value: {vstr}\n" &
            "Value does not match:\n" & errmsg)

proc parse_encoded*(n: Option[YamlNode],
                    validation_info: ValidationInfo):
                    Option[TableRef[JsonNode, string]] =
  const
    errmsg_whole = &"Invalid value of '{EncodedKey}' node\n"
    errmsg_elem  = &"Invalid element in '{EncodedKey}' mapping\n"
  if n.is_none:
    if len(validation_info) > 0:
      raise newException(DefSyntaxError,
              &"'{EncodedKey}' mapping required in definition\n" &
              reqkeysmsg(validation_info) & "\n")
    return TableRef[JsonNode, string].none
  else:
    n.unsafe_get.validate_is_mapping(errmsg_whole)
    var table = newTable[JsonNode, string]()
    for k, v in n.unsafe_get:
      k.validate_is_scalar(errmsg_elem)
      v.validate_is_scalar(errmsg_elem)
      let
        kjson = k.to_json_node
        kjsonstr = $kjson
      if kjsonstr notin validation_info:
        raise newException(DefSyntaxError,
                &"'{EncodedKey}' mapping contains an invalid key\n" &
                &"Invalid key: {kjsonstr}\n")
      validation_info[kjsonstr].found = true
      let vstr = v.to_string
      vstr.validate_vstr(validation_info[kjsonstr].values)
      table[kjson] = vstr
    for k, v in validation_info:
      if v.found == false:
        raise newException(DefSyntaxerror,
              &"Required key missing in '{EncodedKey}'\n" &
              &"Missing key: {k}\n" &
              reqkeysmsg(validation_info) & "\n")
    return table.some
