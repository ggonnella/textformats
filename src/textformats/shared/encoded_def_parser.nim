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
    of viikInt: i_value: int64
    of viikFloat: f_value: float

  ValidationInfo* = TableRef[string,
    tuple[values: seq[ValidationInfoItem], found: bool]]
    # decoded_jsonstr => MatchElem of kind regex (for dt_regex/dt_regexes) or
    #                    float/int/str (for dt_enum)

proc newValidationInfo*(): ValidationInfo =
  newTable[string, tuple[values: seq[ValidationInfoItem], found: bool]]()

proc add*(info: var ValidationInfo, decoded_jsonstr: string, raw: string) =
  if decoded_jsonstr notin info:
    info[decoded_jsonstr] = (values: newseq[ValidationInfoItem](), found: false)
  info[decoded_jsonstr].values.add(ValidationInfoItem(kind: viikRegex,
                                                      r_value:
                                                        (raw: raw,
                                                         compiled: raw.re)))

proc add*(info: var ValidationInfo, decoded_jsonstr: string,
          value: MatchElement) =
  if decoded_jsonstr notin info:
    info[decoded_jsonstr] = (values: newseq[ValidationInfoItem](), found: false)
  let item = block:
    case value.kind:
      of meFloat: ValidationInfoItem(kind: viikFloat, f_value: value.f_value)
      of meInt: ValidationInfoItem(kind: viikInt, i_value: value.i_value)
      of meString: ValidationInfoItem(kind: viikString, s_value: value.s_value)
  info[decoded_jsonstr].values.add(item)

# for dt_enum
proc rm_singletons*(info: var ValidationInfo) =
  var to_rm = newseq[string]()
  for decoded_jsonstr, validation_info_elem in info:
    if validation_info_elem.values.len == 1:
      to_rm.add(decoded_jsonstr)
  for decoded_jsonstr in to_rm:
    info.del(decoded_jsonstr)

const
  EncodedHelp* = "mapping of canonical encoded values (strings) to " &
                 "decoded values (scalar or compound values)"

proc reqdecodedmsg(validation_info: ValidationInfo): string =
  &"Required decoded values(s) for '{EncodedKey}': " &
    to_seq(validation_info.keys).join(", ")

proc validate_encoded_str(encoded_str: string,
                          infoitems: seq[ValidationInfoItem]) =
  var errmsg = ""
  for item in infoitems:
    case item.kind:
    of viikRegex:
      if encoded_str.match(item.r_value.compiled): return
      else: errmsg.add(&"- regex: {item.r_value.raw}\n")
    of viikString:
      if item.s_value == encoded_str: return
      else: errmsg.add(&"- string: {item.s_value}\n")
    of viikFloat:
      try:
       let decoded = parse_float(encoded_str)
       if item.f_value == decoded: return
       else: errmsg.add(&"- float: {item.f_value}\n")
      except ValueError:
       errmsg.add(&"- float: {item.f_value}\n")
    of viikInt:
      try:
       let decoded = parse_int(encoded_str)
       if item.i_value == decoded: return
       else: errmsg.add(&"- integer: {item.i_value}\n")
      except ValueError:
       errmsg.add(&"- integer: {item.i_value}\n")
  raise newException(DefSyntaxError,
            &"'{EncodedKey}' mapping contains an invalid encoded value\n" &
            &"Invalid encoded value: {encoded_str}\n" &
            "Value does not match:\n" & errmsg)

proc parse_encoded*(n: OptYamlNode,
                    validation_info: ValidationInfo):
                    Option[TableRef[JsonNode, string]] =
  if n.is_none:
    if len(validation_info) == 1:
      let decoded_jsonstr = to_seq(validation_info.keys)[0]
      raise newException(DefSyntaxError,
              &"'{EncodedKey}' key required in definition,\n" &
              "since it is unclear which text representation\n" &
              &"to use for encoding the value: {decoded_jsonstr}\n")
    elif len(validation_info) > 1:
      raise newException(DefSyntaxError,
              &"'{EncodedKey}' mapping required in definition\n" &
              reqdecodedmsg(validation_info) & "\n")
    return TableRef[JsonNode, string].none
  else:
    if n.unsafe_get.is_scalar:
      var table = newTable[JsonNode, string]()
      let
        decoded_jsonstr = to_seq(validation_info.keys)[0]
        decoded_json = parseJson(decoded_jsonstr)
        encoded_str = n.unsafe_get.to_string
      encoded_str.validate_encoded_str(validation_info[decoded_jsonstr].values)
      table[decoded_json] = encoded_str
      return table.some
    elif n.unsafe_get.is_mapping:
      var table = newTable[JsonNode, string]()
      for encoded, decoded in n.unsafe_get:
        const errmsg_elem = &"Invalid element in '{EncodedKey}' mapping\n"
        encoded.validate_is_scalar(errmsg_elem)
        let
          decoded_json = decoded.to_json_node
          decoded_jsonstr = $decoded_json
        if decoded_jsonstr notin validation_info:
          raise newException(DefSyntaxError,
                  &"'{EncodedKey}' mapping contains an invalid decoded value\n" &
                  &"Invalid decoded value: {decoded_jsonstr}\n")
        validation_info[decoded_jsonstr].found = true
        let encoded_str = encoded.to_string
        encoded_str.validate_encoded_str(validation_info[decoded_jsonstr].values)
        table[decoded_json] = encoded_str
      for decoded_jsonstr, validation_info_elem in validation_info:
        if validation_info_elem.found == false:
          raise newException(DefSyntaxerror,
                &"Required decoded value missing in '{EncodedKey}'\n" &
                &"Missing decoded value: {decoded_jsonstr}\n" &
                reqdecodedmsg(validation_info) & "\n")
      return table.some
    else:
      if len(validation_info) == 0:
        raise newException(DefSyntaxError,
                &"'{EncodedKey}' key superfluous in definition\n")
      elif len(validation_info) == 1:
        let decoded_jsonstr = to_seq(validation_info.keys)[0]
        raise newException(DefSyntaxError,
                &"'{EncodedKey}' shall contain a string\n" &
                "since it is unclear which text representation to use\n" &
                &"for encoding a single decoding value: {decoded_jsonstr}\n")
      elif len(validation_info) > 1:
        raise newException(DefSyntaxError,
                &"'{EncodedKey}' shall contain a mapping\n" &
                reqdecodedmsg(validation_info) & "\n")
      return TableRef[JsonNode, string].none
