import json, strformat, strutils, tables, sets
import ../types / [datatype_definition, textformats_error, file_lines_reader]
import dict_decoder

template foreach_dict_section_element(reader, dd, actions: untyped) =
  var i = 0
  while true:
    if reader.eof: break
    try:
      actions
      reader.consume
      i += 1
    except DecodingError:
      if i == 0:
        raise newException(DecodingError, "Dict has no elements\n" &
                           get_current_exception_msg().indent(2))
      break

proc decode_dict_section*(reader: var FileLinesReader,
                          dd: DatatypeDefinition): JsonNode =
  result = newJObject()
  foreach_dict_section_element(reader, dd):
    reader.line.decode_element(dd, result.fields)
  result.fields.validate_required(dd)
  for (k, v) in dd.implicit:
    result.fields[k] = v

template foreach_dict_section_line(reader, dd, line_actions: untyped) =
  var previous_dkeys = initHashSet[string]()
  let pfx = if len(key) > 0: &"{key}." else: ""
  foreach_dict_section_element(reader, dd):
    var obj {.inject.} = newJObject()
    let (dkey, value_str) = parse_and_validate_element(reader.line,
                                                dd, previous_dkeys)
    previous_dkeys.incl(dkey)
    obj[pfx & dkey] = value_str.decode_value(dd, dkey)
    line_actions
  previous_dkeys.validate_required(dd)
  for (k, v) in dd.implicit:
    var obj {.inject.} = newJObject()
    obj[pfx & k] = v
    line_actions

proc decode_dict_section_lines*(reader: var FileLinesReader,
                        dd: DatatypeDefinition, key: string,
                        line_processor: proc(decoded_line: JsonNode)) =
  foreach_dict_section_line(reader, dd):
    line_processor(obj)

iterator decoded_dict_section_elements*(reader: var FileLinesReader,
                        dd: DatatypeDefinition, key: string): JsonNode =
  foreach_dict_section_line(reader, dd):
    yield obj
