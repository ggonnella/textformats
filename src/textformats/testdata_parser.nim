##
## Parse a YAML testdata node and run tests
##

import types / [specification, textformats_error, def_syntax,
                datatype_definition]
import support/yaml_support
import strutils, strformat, tables, json
import decoder, encoder, encoded_validator, decoded_validator
import yaml, yaml / [dom, serialization, hints]

proc get_yaml_root(filename: string): YamlNode =
  get_yamlfile_mapping_root(TextformatsRuntimeError,
                            InvalidTestdataError, filename,
                            "testdata")

proc get_map_node(n: YamlNode, key: string): Option[YamlNode] {.inline.} =
  # ignore ProveInit warning thrown by options library
  {.warning[ProveInit]: off.}
  try:
    let v = n[key]
    return some(v)
  except KeyError:
    return none(YamlNode)

proc get_testdata_node(root: YamlNode): YamlNode =
  var node = YamlNode.none
  try:
    let whole_errmsg = &"Expected: mapping with key '{TestdataRootKey}'"
    root.validate_is_mapping("Invalid YAML content\n", "\n" & whole_errmsg)
    node = root.get_map_node(TestdataRootKey)
    if node.is_some:
      node.unsafe_get.validate_is_mapping(
        &"  Invalid content of '{TestdataRootKey}' key\n",
        "  It must be a mapping containing test data")
      return node.unsafe_get
    else:
      raise newException(InvalidTestdataError,
        "  Invalid content of YAML mapping\n" & whole_errmsg)
  except NodeValueError:
    raise newException(InvalidTestdataError, get_current_exception_msg())

proc test_encoded_validation(input: string, datatype: DatatypeDefinition,
                             failed: string, success: string) =
  if not input.is_valid(datatype):
    raise newException(UnexpectedEncodedInvalidError, failed &
      &"  Encoded data: {input}\n" &
      &"  Expected to be valid, but validation failed\n")
  else:
    echo(&"{success}'{input}' (encoded) validated")

proc test_encoded_no_validation(input: string, datatype: DatatypeDefinition,
                                failed: string, success: string) =
  if input.is_valid(datatype):
    raise newException(UnexpectedEncodedValidError, failed &
      &"  Encoded data: {input}\n" &
      &"  Expected to be invalid, but validation succeded\n")
  else:
    echo(&"{success}'{input}' (encoded) not validated")

proc test_decoded_validation(input: JsonNode, datatype: DatatypeDefinition,
                             failed: string, success: string) =
  if not input.is_valid(datatype):
    raise newException(UnexpectedDecodedInvalidError,
      failed &
      &"  Decoded data: {input}\n" &
      &"  Expected to be valid, but validation failed\n")
  else:
    echo(&"{success}'{input}' (decoded) validated")

proc test_decoded_no_validation(input: JsonNode, datatype: DatatypeDefinition,
                                failed: string, success: string) =
  if input.is_valid(datatype):
    raise newException(UnexpectedDecodedValidError,
      failed &
      &"  Decoded data: {input}\n" &
      &"  Expected to be invalid, but validation succeeded\n")
  else:
    echo(&"{success}'{input}' (decoded) not validated")

proc test_valid_decoding(input: string, datatype: DatatypeDefinition,
                         expected: JsonNode, failed: string, success: string) =
  try:
    let output = input.decode(datatype)
    if output != expected:
      raise newException(UnexpectedDecodingResultError,
        failed &
        "  Decoding result different than expected\n" &
        &"  Expected: {expected}\n" &
        &"  Decoded:  {output}")
    else:
      echo(&"{success}'{input}' =(decode)=> '{output}'")
  except DecodingError:
    raise newException(UnexpectedEncodedInvalidError,
      failed &
      &"  Encoded data: {input}\n" &
      &"  Expected decoding output: {expected}\n" &
      "  Instead, decoding failed with an error:\n" &
      get_current_exception_msg().indent(4))

proc test_valid_encoding(input: JsonNode, datatype: DatatypeDefinition,
                         expected: string, failed: string, success: string) =
  try:
    let output = input.encode(datatype)
    if output != expected:
      raise newException(UnexpectedEncodingResultError, failed &
        "  Encoding result different than expected\n" &
        &"  Expected: {expected}\n" &
        &"  Decoded:  {output}")
    else:
      echo(&"{success}'{input}' =(encode)=> '{output}'")
  except EncodingError:
    raise newException(UnexpectedDecodedInvalidError, failed &
      &"  Decoded data: {input}\n" &
      &"  Expected encoding output: {expected}\n" &
      "  Instead, encoding failed with an error:\n" &
      get_current_exception_msg().indent(4))

proc run_valid_data_list_tests(datatype: DatatypeDefinition,
                               valid_list: YamlNode, dtmsg: string,
                               whole_err: string, helpmsg: string,
                               failed: string, success: string) =
  for element_node in valid_list:
    element_node.validate_is_string(dtmsg & whole_err.indent(2) &
      &"  List element is not a string: {element_node}\n",
      helpmsg.indent(2))
    let
      element = element_node.to_string()
      element_json = %(element)
    test_valid_decoding(element, datatype, element_json, failed, success)
    test_encoded_validation(element, datatype, failed, success)
    test_valid_encoding(element_json, datatype, element, failed, success)
    test_decoded_validation(element_json, datatype, failed, success)

proc run_valid_data_map_tests(datatype: DatatypeDefinition,
                              valid_map: YamlNode, dtmsg: string,
                              whole_err: string, helpmsg: string,
                              failed: string, success: string,
                              oneway: bool) =
  for subkey_node, subvalue in valid_map:
    subkey_node.validate_is_string(dtmsg & whole_err.indent(2) &
      &"  Mapping key is not a string: {subkey_node}\n",
      helpmsg.indent(2))
    let
      subkey = subkey_node.to_string()
      subvalue_json = subvalue.to_json_node()
    test_valid_decoding(subkey, datatype, subvalue_json, failed, success)
    test_encoded_validation(subkey, datatype, failed, success)
    if not oneway:
      test_valid_encoding(subvalue_json, datatype, subkey, failed, success)
      test_decoded_validation(subvalue_json, datatype, failed, success)

proc test_invalid_encoded(encoded: string, datatype: DatatypeDefinition,
                          failed: string, success: string) =
  try:
    let decoded = encoded.decode(datatype)
    raise newException(UnexpectedEncodedValidError, failed &
      &"  Encoded input data: {encoded}\n" &
      "  The encoded data should be invalid " &
      "  but the decoding unexpectedly succeded\n" &
      &"  Output: {decoded}\n")
  except DecodingError:
    echo(&"{success}decoding '{encoded}' failed as expected")

proc run_invalid_encoded_test(datatype: DatatypeDefinition,
                              encoded_list: YamlNode, dtmsg: string,
                              failed: string, success: string) =
  let helpmsg = "The content must be " &
    "a list containing invalid encoded values.\n"
  let whole_err = &"Invalid content of '{TestdataEncodedKey}'\n"
  encoded_list.validate_is_sequence(dtmsg & whole_err.indent(2),
                        helpmsg.indent(2))
  for element_node in encoded_list:
    element_node.validate_is_string(dtmsg & whole_err.indent(2),
      &"  List element is not a string: '{element_node}'\n" &
      helpmsg.indent(2))
    let element = element_node.to_string
    test_invalid_encoded(element, datatype, failed, success)
    test_encoded_no_validation(element, datatype, failed, success)

proc test_invalid_decoded(decoded: JsonNode, datatype: DatatypeDefinition,
                          failed: string, success: string) =
  try:
    let encoded = decoded.encode(datatype)
    raise newException(UnexpectedDecodedValidError, failed &
      &"  Decoded input data: {decoded}\n" &
      "  The decoded data should be invalid " &
      "  but the encoding unexpectedly succeded\n" &
      &"Output: {encoded}\n")
  except EncodingError:
    echo(&"{success}encoding '{decoded}' failed as expected")

proc run_invalid_decoded_test(datatype: DatatypeDefinition,
                              decoded_list: YamlNode, dtmsg: string,
                              failed: string, success: string) =
  let helpmsg = "The content must be " &
    "a list containing invalid decoded values.\n"
  let whole_err = &"Invalid content of '{TestdataDecodedKey}'\n"
  decoded_list.validate_is_sequence(dtmsg & whole_err.indent(2),
                        helpmsg.indent(2))
  for element_node in decoded_list:
    let element = element_node.to_json_node
    test_invalid_decoded(element, datatype, failed, success)
    test_decoded_no_validation(element, datatype, failed, success)

proc run_invalid_data_list_tests(datatype: DatatypeDefinition,
                                 invalid_list: YamlNode, dtmsg: string,
                                 failed: string, success: string) =
  let helpmsg = "The content must be " &
    "a list containing invalid invariant (decoded==encoded) values.\n"
  let whole_err = &"Invalid content of '{TestdataInvalidKey}' list\n"
  for element_node in invalid_list:
    element_node.validate_is_string(dtmsg & whole_err.indent(2) &
      &"  List element is not a string: {element_node}\n",
      helpmsg.indent(2))
    let
      element = element_node.to_string()
      element_json = %(element)
    test_invalid_encoded(element, datatype, failed, success)
    test_encoded_no_validation(element, datatype, failed, success)
    test_invalid_decoded(element_json, datatype, failed, success)
    test_decoded_no_validation(element_json, datatype, failed, success)

proc run_invalid_data_map_tests(datatype: DatatypeDefinition,
                                invalid_map: YamlNode, dtmsg: string,
                                whole_err: string, helpmsg: string,
                                failed: string, success: string) =
  for subkey_node, subvalue in invalid_map:
    subkey_node.validate_is_string(dtmsg & whole_err.indent(2) &
      &"  Mapping key is not a string: {subkey_node}\n",
      helpmsg.indent(2))
    let subkey = subkey_node.to_string()
    case subkey:
    of TestdataEncodedKey:
      run_invalid_encoded_test(datatype, subvalue, dtmsg, failed, success)
    of TestdataDecodedKey:
      run_invalid_decoded_test(datatype, subvalue, dtmsg, failed, success)
    else:
      raise newException(InvalidTestdataError, dtmsg &
        whole_err.indent(2) & helpmsg.indent(2))

proc test_specification*(spec: Specification, filename: string) =
  let
    root = filename.get_yaml_root
    testdata_node = root.get_testdata_node()
  for datatype_name_node, datatype_testdata in testdata_node:
    var datatype: DatatypeDefinition
    datatype_name_node.validate_is_string(
        &"  Invalid content of '{TestdataRootKey}'\n" &
        "  Datatype name must be a string\n",
        &"  Wrong element: '{datatype_name_node}'")
    let datatype_name = datatype_name_node.to_string()
    if datatype_name notin spec:
      raise newException(InvalidTestdataError,
        &"  Invalid content of '{TestdataRootKey}'\n" &
        &"  Datatype not found in the specification: {datatype_name}")
    else:
      datatype = spec[datatype_name]
    let
      dtmsg = &"[Error] Testdata for datatype: '{datatype_name}':\n"
      failed = &"[Failed] Datatype: '{datatype_name}':\n"
      success = &"[OK] Datatype: '{datatype_name}': "
    for key_node, value in datatype_testdata.pairs:
      key_node.validate_is_string()
      let key = key_node.to_string()
      case key:
      of TestdataValidKey:
        let helpmsg = "The content may only be one of the following:\n" &
          "- a list of valid invariant (decoded==encoded) string values\n" &
          "- a mapping of valid string representations to decoded values\n"
        let whole_err = &"Invalid content of '{TestdataValidKey}'\n"
        value.validate_is_not_scalar(dtmsg & whole_err.indent(2),
                                     helpmsg.indent(2))
        if value.is_sequence:
          run_valid_data_list_tests(datatype, value, dtmsg, whole_err, helpmsg,
            failed, success)
        else: # value.is_mapping
          run_valid_data_map_tests(datatype, value, dtmsg, whole_err, helpmsg,
                                   failed, success, false)
      of TestdataOnewayKey:
        let helpmsg = "The content must be " &
          "a mapping of valid string representations to decoded values\n"
        let whole_err = &"Invalid content of '{TestdataOnewayKey}'\n"
        value.validate_is_mapping(dtmsg & whole_err.indent(2),
                                  helpmsg.indent(2))
        run_valid_data_map_tests(datatype, value, dtmsg, whole_err, helpmsg,
                                 failed, success, true)
      of TestdataInvalidKey:
        let helpmsg = "The content may only be one of the following:\n" &
          "- a list of invalid invariant (decoded==encoded) string values\n" &
          "- a mapping containing one or both of the keys: " &
          &"'{TestdataEncodedKey}', '{TestdataDecodedKey}'\n"
        let whole_err = &"Invalid content of '{TestdataInvalidKey}'\n"
        value.validate_is_not_scalar(dtmsg & whole_err.indent(2),
                                     helpmsg.indent(2))
        if value.is_sequence:
          run_invalid_data_list_tests(datatype, value, dtmsg, failed, success)
        else: # value.is_mapping:
          run_invalid_data_map_tests(datatype, value, dtmsg, whole_err, helpmsg,
            failed, success)
      else:
        raise newException(InvalidTestdataError,
          dtmsg &
          "  Unexpected key found: '{node_name}'.\n" &
          &"  Accepted keys: '{TestdataValidKey}', " &
          &"'{TestdataOnewayKey}', '{TestdataInvalidKey}'.")

proc list_testdata_datatypes*(filename: string): seq[string] =
  ## List the datatypes in a yaml testdata file
  result = newSeq[string]()
  let
    root = filename.get_yaml_root
    testdata_node = root.get_testdata_node()
  for datatype_name_node, datatype_testdata in testdata_node:
    result.add(datatype_name_node.to_string())
