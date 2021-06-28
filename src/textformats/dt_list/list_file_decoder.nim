import json, options, strformat
import ../support/openrange
import ../types / [datatype_definition, textformats_error, file_lines_reader]
import list_decoder
import ../file_decoder

proc decode_list_file_section*(reader: var FileLinesReader,
                               dd: DatatypeDefinition): JsonNode =
  result = newJArray()
  var i = 0
  while i <= dd.lenrange.high:
    if reader.eof:
      if i < dd.lenrange.low: raise_invalid_list_size(i, dd)
      else: break
    try:
      result.add(reader.decode_file_section(dd.members_def))
      i += 1
    except DecodingError:
      if i == 0 or i < dd.lenrange.low:
        raise_invalid_list_element(i, dd, get_current_exception_msg())
      else: break

proc decode_list_file_section_lines*(reader: var FileLinesReader,
                        dd: DatatypeDefinition, key: string,
                        line_processor: proc(decoded_line: JsonNode)) =
  var i = 0
  while i <= dd.lenrange.high:
    if reader.eof:
      if i < dd.lenrange.low: raise_invalid_list_size(i, dd)
      else: break
    try:
      reader.decode_file_section_lines(dd.members_def, &"{key}[{i+1}]",
                                       line_processor)
      i += 1
    except DecodingError:
      if i == 0 or i < dd.lenrange.low:
        raise_invalid_list_element(i, dd, get_current_exception_msg())
      else: break

