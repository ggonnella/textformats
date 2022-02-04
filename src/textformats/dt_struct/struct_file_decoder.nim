import strformat, json
import ../types / [datatype_definition, textformats_error, file_lines_reader]
import struct_decoder
import ../file_decoder

template foreach_struct_section_element(reader, dd, break_on_err,
                                        actions: untyped) =
  var element_num = 0
  for mem in dd.members:
    if reader.eof:
      if element_num < dd.n_required:
        raise_invalid_min_n_elements(element_num, dd.n_required)
      else:
        break
    try:
      let member {.inject.} = mem
      actions
      inc element_num
    except DecodingError:
      if break_on_err:
        if element_num < dd.n_required:
          raise_invalid_element(get_current_exception_msg(), mem.name)
        break
      else: continue
  if element_num < dd.n_required:
    raise_invalid_min_n_elements(element_num, dd.n_required)

proc decode_struct_section*(reader: var FileLinesReader,
                            dd: DatatypeDefinition): JsonNode =
  result = newJObject()
  foreach_struct_section_element(reader, dd, true):
    result[member.name] = reader.decode_section(member.def)

proc decode_struct_section_lines*(reader: var FileLinesReader,
                        dd: DatatypeDefinition, key: string,
                        line_processor: proc(decoded_line: JsonNode,
                                             data: pointer = nil),
                        line_processor_data: pointer = nil) =
  let pfx = if len(key) > 0: &"{key}." else: ""
  foreach_struct_section_element(reader, dd, false):
    reader.decode_section_lines(member.def, pfx & member.name, line_processor,
                                line_processor_data)

iterator decoded_struct_section_elements*(reader: var FileLinesReader,
                        dd: DatatypeDefinition, key: string): JsonNode =
  let pfx = if len(key) > 0: &"{key}." else: ""
  foreach_struct_section_element(reader, dd, false):
    var obj = newJObject()
    obj[pfx & member.name] = reader.decode_section(member.def)
    yield obj

