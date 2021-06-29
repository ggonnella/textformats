import strformat, options, json
import ../types / [datatype_definition, textformats_error, file_lines_reader]
import struct_decoder
import ../file_decoder

proc decode_struct_section*(reader: var FileLinesReader,
                                 dd: DatatypeDefinition): JsonNode =
  result = newJObject()
  var i = 0
  for member in dd.members:
    if reader.eof:
      if i < dd.n_required:
        raise_invalid_min_n_elements(i, dd.n_required)
      else:
        break
    try:
      result[member.name] = reader.decode_section(member.def)
      i += 1
    except DecodingError:
      if i < dd.n_required:
        raise_invalid_element(get_current_exception_msg(), member.name)
      else:
        break

proc decode_struct_section_lines*(reader: var FileLinesReader,
                        dd: DatatypeDefinition, key: string,
                        line_processor: proc(decoded_line: JsonNode)) =
  let pfx = if len(key) > 0: &"{key}." else: ""
  var i = 0
  for member in dd.members:
    if reader.eof:
      if i < dd.n_required:
        raise_invalid_min_n_elements(i, dd.n_required)
      else:
        break
    try:
      reader.decode_section_lines(member.def, pfx & member.name,
                                       line_processor)
      i += 1
    except DecodingError:
      continue
  if i < dd.n_required:
    raise_invalid_min_n_elements(i, dd.n_required)

