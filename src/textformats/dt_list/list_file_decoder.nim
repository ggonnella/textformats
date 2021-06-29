import json, options, strformat
import ../support/openrange
import ../types / [datatype_definition, textformats_error, file_lines_reader]
import list_decoder
import ../file_decoder

template foreach_list_section_element(reader, dd, actions: untyped) =
  var element_num {.inject.} = 0
  while element_num <= dd.lenrange.high:
    if reader.eof:
      if element_num < dd.lenrange.low: raise_invalid_list_size(element_num, dd)
      else: break
    try:
      actions
      inc element_num
    except DecodingError:
      if element_num == 0 or element_num < dd.lenrange.low:
        raise_invalid_list_element(element_num, dd, get_current_exception_msg())
      else: break

proc decode_list_section*(reader: var FileLinesReader,
                          dd: DatatypeDefinition): JsonNode =
  result = newJArray()
  foreach_list_section_element(reader, dd):
    result.add(reader.decode_section(dd.members_def))

proc decode_list_section_lines*(reader: var FileLinesReader,
                        dd: DatatypeDefinition, key: string,
                        line_processor: proc(decoded_line: JsonNode)) =
  foreach_list_section_element(reader, dd):
    reader.decode_section_lines(dd.members_def, &"{key}[{element_num+1}]",
                                line_processor)

iterator decoded_list_section_elements*(reader: var FileLinesReader,
                        dd: DatatypeDefinition, key: string): JsonNode =
  foreach_list_section_element(reader, dd):
    let objkey = &"{key}[{element_num+1}]"
    var obj = newJObject()
    obj[objkey] = reader.decode_section(dd.members_def)
    yield obj

