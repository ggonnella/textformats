import json, strformat, strutils, tables, sets
import ../types / [datatype_definition, textformats_error, file_lines_reader]
import dict_decoder

##
## decode lines which are elements of a dict, until a line
## is found, which does not respect the definition
##
## the entire set of lines belonging to the dict is stored in memory;
## a more efficient way to handle large files is the
## decode_and_process_dict_lines
##
proc decode_dict_section*(reader: var FileLinesReader,
                               dd: DatatypeDefinition): JsonNode =
  result = newJObject()
  var i = 0
  while true:
    if reader.eof: break
    try:
      reader.line.decode_element(dd, result.fields)
      reader.consume
      i += 1
    except DecodingError:
      if i == 0:
        raise newException(DecodingError, "Dict has no elements\n" &
                           get_current_exception_msg().indent(2))
      break
  result.fields.validate_required(dd)
  for (k, v) in dd.implicit:
    result.fields[k] = v

##
## decode lines which are elements of a dict, until a line
## is found, which does not respect the definition
##
## each time a line is successfully decoded, the line is processed
## using the passed action proc
##
proc decode_dict_section_lines*(reader: var FileLinesReader,
                        dd: DatatypeDefinition, key: string,
                        line_processor: proc(decoded_line: JsonNode)) =
  var
    i = 0
    previous_dkeys = initHashSet[string]()
  let pfx = if len(key) > 0: &"{key}." else: ""
  while true:
    if reader.eof: break
    try:
      var obj = newJObject()
      let (dkey, value_str) = parse_and_validate_element(reader.line,
                                                  dd, previous_dkeys)
      previous_dkeys.incl(dkey)
      obj[pfx & dkey] = value_str.decode_value(dd, dkey)
      line_processor(obj)
      reader.consume
      i += 1
    except DecodingError:
      if i == 0:
        raise newException(DecodingError, "Dict has no elements\n" &
                           get_current_exception_msg().indent(2))
      else:
        break
  previous_dkeys.validate_required(dd)
  for (k, v) in dd.implicit:
    var obj = newJObject()
    obj[pfx & k] = v
    line_processor(obj)
