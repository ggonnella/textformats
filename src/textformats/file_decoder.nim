import strutils, strformat, options, json
import decoder
import types / [datatype_definition, textformats_error, file_lines_reader]

proc decode_section*(reader: var FileLinesReader,
                     dd: DatatypeDefinition): JsonNode

proc decode_section_lines*(reader: var FileLinesReader,
                           dd: DatatypeDefinition, key: string,
                           line_processor: proc(decoded_line: JsonNode,
                                                data: pointer),
                           line_processor_data: pointer)

import dt_list/list_file_decoder
import dt_struct/struct_file_decoder
import dt_dict/dict_file_decoder
#import dt_tags/tags_file_decoder

template open_input_file(filename: string): File =
  if filename == "":
    stdin
  else:
    var file: File = nil
    try: file = open(filename)
    except IOError:
      let e = getCurrentException()
      raise newException(TextFormatsRuntimeError,
                         "Error while reading input file '" & filename &
                         "'\n" & e.msg)
    file

#
# State for parsing embedded specification files
#

type
  dataParsingState = enum
    dpsPre, dpsYaml, dpsData

proc dps_init(embedded: bool): dataParsingState {.inline.} =
  if embedded: dpsPre else: dpsData

proc dps_pre_transition(line: string): dataParsingState {.inline.} =
  let uncommented = line.split("#")[0]
  if len(uncommented.strip) > 0: dpsYaml else: dpsPre

proc dps_yaml_transition(line: string): dataParsingState {.inline.} =
  if line == "---": dpsData else: dpsYaml

iterator decoded_lines_or_units(filename: string, dd: DatatypeDefinition,
                                embedded = false): JsonNode =
  let file = open_input_file(filename)
  var
    ddef = dereference(dd)
    line_no = 0
    state = dps_init(embedded)
    linesgroup = newseq[string](ddef.unitsize)
    n_in_group = 0
    shall_decode = true
  if ddef.unitsize < 1:
    ddef.unitsize = 1
  for line in lines(file):
    line_no += 1
    case state:
    of dpsData:
      if ddef.unitsize > 1:
        linesgroup[n_in_group] = line
        n_in_group += 1
        shall_decode = (n_in_group == ddef.unitsize)
      if shall_decode:
        try:
          if ddef.unitsize > 1:
            yield linesgroup.join("\n").decode(ddef)
            n_in_group = 0
          else:
            yield line.decode(ddef)
        except DecodingError:
          var msg = &"File: '{filename}'\n" &
                    &"Line number: {line_no}\n"
          raise newException(DecodingError, msg & getCurrentExceptionMsg())
    of dpsPre:
      state = dps_pre_transition(line)
    of dpsYaml:
      state = dps_yaml_transition(line)
  file.close
  if n_in_group > 0:
    raise newException(DecodingError,
                       &"File: '{filename}'\n" &
                       "Final group of lines does not contain enough lines\n" &
                       &"Found n. of lines: {n_in_group}\n" &
                       &"Required n. of lines: {ddef.unitsize}")

#
#
# Note:
#
# the file_section decoders work using a definition which must have
# a newline as separator and can be ddkList, ddkStruct, ddkDict or ddkTags
#
# in the case of ddkList and ddkStruct the elements themselves are allowed
# to be newline-separated compound values, thus defining a hierarchy of
# line-based definitions
#
# this hierarchical lines-based definition is not supported in case of
# ddkDict and ddkTags (currently); note also that this would require both the
# internal separator and the separator to be newlines, but in the current
# implementation the two separators must be different from each other
#

template on_section_def(ddef, actions_true: untyped, actions_false: untyped) =
  if ddef.sep == "\n":
    try:
      actions_true
    except DecodingError:
      raise_decoding_error(reader.line, get_current_exception_msg(), ddef)
  else:
    actions_false
    reader.consume

proc decode_section*(reader: var FileLinesReader,
                     dd: DatatypeDefinition): JsonNode =
  let ddef = dereference(dd)
  on_section_def(ddef):
      case ddef.kind:
      of ddkStruct: result = reader.decode_struct_section(ddef)
      of ddkList:   result = reader.decode_list_section(ddef)
      of ddkDict:   result = reader.decode_dict_section(ddef)
      #of ddkTags:   result = reader.decode_tags_section(ddef)
      else: assert(false)
  do:
    result = reader.line.decode(ddef)

proc decode_section_lines*(reader: var FileLinesReader,
                           dd: DatatypeDefinition, key: string,
                           line_processor: proc(decoded_line: JsonNode,
                                                data: pointer),
                           line_processor_data: pointer) =
  let ddef = dereference(dd)
  on_section_def(ddef):
    case ddef.kind:
    of ddkStruct:
      reader.decode_struct_section_lines(ddef, key, line_processor,
                                         line_processor_data)
    of ddkList:
      reader.decode_list_section_lines(ddef, key, line_processor,
                                       line_processor_data)
    of ddkDict:
      reader.decode_dict_section_lines(ddef, key, line_processor,
                                       line_processor_data)
    #of ddefkTags:
    #  reader.decode_tags_section_lines(ddef, key, line_processor,
    #                                   line_processor_data)
    else: assert(false)
  do:
    var obj = newJObject()
    obj[key] = reader.line.decode(ddef)
    line_processor(obj, line_processor_data)

iterator decoded_section_elements(reader: var FileLinesReader,
                                  dd: DatatypeDefinition, key: string):
                                     JsonNode =
  let ddef = dereference(dd)
  on_section_def(ddef):
    case ddef.kind:
    of ddkStruct:
      for line in reader.decoded_struct_section_elements(ddef, key):
        yield line
    of ddkList:
      for line in reader.decoded_list_section_elements(ddef, key):
        yield line
    of ddkDict:
      for line in reader.decoded_dict_section_elements(ddef, key):
        yield line
    #of ddefkTags:
    #  for line in reader.decoded_tags_section_elements(ddef, key):
    #    yield line
    else: assert(false)
  do:
    var obj = newJObject()
    obj[key] = reader.line.decode(ddef)
    yield obj

proc validate_section_def(dd: DatatypeDefinition) =
  if dd.kind notin @[ddkStruct, ddkList, ddkDict]:
    raise newException(TextFormatsRuntimeError,
            "Wrong datatype definition for file section\n" &
            "Expected: composed_of, list_of or labeled_list\n" &
            &"Found: '{dd.kind}'")
  if dd.sep != "\n":
    raise newException(TextFormatsRuntimeError,
            "Wrong separator for file section definition\n" &
            "Expected: newline\n" &
            &"Found: '{dd.sep}'")
  if dd.pfx.len > 0:
    raise newException(TextFormatsRuntimeError,
            "Wrong prefix for file section definition\n" &
            "Expected: empty string\n" &
            &"Found: '{dd.pfx}'")
  if dd.sfx.len > 0:
    raise newException(TextFormatsRuntimeError,
            "Wrong suffix for file section definition\n" &
            "Expected: empty string\n" &
            &"Found: '{dd.sfx}'")

template raise_not_whole(filename: string, reader: FileLinesReader) =
  raise newException(DecodingError,
     "Error: Datatype definition applies to a section of the file only\n" &
     "Filename: " & filename &
     "\nExpected: datatype definition for whole file\n" &
     "Last line number of file section: " & $reader.lineno & "\n")

template onDataLines(filename, embedded, dd, whole, actions: untyped) =
  var
    file = open_input_file(filename)
    reader {.inject.} = new_file_lines_reader(file)
    state = dps_init(embedded)
    section = 0
  let ddef {.inject.} = dd.dereference
  ddef.validate_section_def
  while not reader.eof:
    case state:
    of dpsPre:
      state = dps_pre_transition(reader.line)
      reader.consume
    of dpsYaml:
      state = dps_yaml_transition(reader.line)
      reader.consume
    of dpsData:
      if whole and section > 0:
        raise_not_whole(filename, reader)
      actions
      inc section
  file.close

iterator decoded_sections(filename: string, dd: DatatypeDefinition,
                          embedded=false): JsonNode =
  ##
  ## Decode a file as a list of multiline sections.
  ## Each of the sections is defined by the datatype definition,
  ## as a multiline section, i.e. a ddkStruct, ddkList or ddkDict definition
  ## (or a reference to it) ## with a "\n" separator, and no pfx or sfx.
  ##
  ## This is targeted at sections of a file, consisting of multiple lines,
  ## where the number of lines is not known in advance.
  ##
  ## This iterator yields the entire content of each file section at
  ## once. For large files decoded_section_lines/elements can be more efficient.
  ##
  onDataLines(filename, embedded, dd, false):
    yield reader.decode_section(ddef)

proc decoded_whole_file(filename: string, dd: DatatypeDefinition,
                        embedded=false): JsonNode =
  ##
  ## Decode a file using a datatype definition for the whole file,
  ## i.e. a ddkStruct, ddkList or ddkDict definition (or a reference to it)
  ## with a "\n" separator, and no pfx or sfx.
  ##
  ## This is targeted at files, consisting of multiple lines,
  ## where the number of lines is not known in advance.
  ##
  ## This function returns the entire content of the file at once.
  ## For large files decoded_whole_file_lines/elements can be more efficient.
  ##
  onDataLines(filename, embedded, dd, true):
    result = reader.decode_section(ddef)

proc decode_section_lines(filename: string, dd: DatatypeDefinition,
                           line_processor: proc(decoded_line: JsonNode,
                                                data: pointer),
                           line_processor_data: pointer,
                           embedded=false) =
  ##
  ## Decode a file using a definition which defines the structure of the file
  ## section, as a compound datatype with newline as separator, but processing
  ## each of the decoded lines separately.
  ##
  ## This function passes each of the decoded lines to line_processor.
  ## For a similar function returning the decoded compound value
  ## see decode_by_file_def.
  ##
  ## The function pointer argument is used, since the function cannot be
  ## implemented as iterator because recursive iterators are not available in
  ## Nim. The iterator version is decoded_section_elements, which, however,
  ## does not split recursively into lines if a section definitions
  ## are nested.
  ##
  onDataLines(filename, embedded, dd, false):
    reader.decode_section_lines(ddef, "", line_processor, line_processor_data)

proc decode_whole_file_lines(filename: string, dd: DatatypeDefinition,
                              line_processor: proc(decoded_line: JsonNode,
                                                   data: pointer),
                              line_processor_data: pointer,
                              embedded=false) =
  ##
  ## Decode a file using a definition which defines the entire structure of the
  ## file as a compound datatype with newline as separator, but processing each
  ## of the decoded lines separately.
  ##
  ## This function passes each of the decoded lines to line_processor.
  ## For a similar function returning the decoded compound value
  ## see decode_by_file_def.
  ##
  ## The function pointer argument is used, since the function cannot be
  ## implemented as iterator because recursive iterators are not available in
  ## Nim. The iterator version is decoded_whole_file_elements, which, however,
  ## does not split recursively into lines if a section definitions
  ## are nested.
  ##
  onDataLines(filename, embedded, dd, true):
    reader.decode_section_lines(ddef, "", line_processor, line_processor_data)

iterator decoded_section_elements(filename: string, dd: DatatypeDefinition,
                                   embedded=false): JsonNode =
  ##
  ## Decode a file using a definition which defines an entire
  ## file section as a compound datatype with newline as separator.
  ##
  ## This iterator works as decoded_section_lines, however, due to
  ## limitations ## of the iterators (which cannot be recursive)
  ## if a section element is multi-line, then it will be yield at once.
  ##
  onDataLines(filename, embedded, dd, false):
    for line in reader.decoded_section_elements(ddef, ""):
      yield line

iterator decoded_whole_file_elements(filename: string, dd: DatatypeDefinition,
                                   embedded=false): JsonNode =
  ##
  ## Decode a whole file using a definition which defines the entire
  ## structure of the file as a compound datatype with newline as separator.
  ##
  ## This iterator works as decoded_whole_file_lines, however, due to
  ## limitations ## of the iterators (which cannot be recursive)
  ## if a section element is multi-line, then it will be yield at once.
  ##
  onDataLines(filename, embedded, dd, true):
    for line in reader.decoded_section_elements(ddef, ""):
      yield line

proc show_decoded(decoded: JsonNode, data: pointer) =
  echo $decoded

## Level to which the process_decoded function shall be applied
type DecodedProcessorLevel* = enum
  DplWhole =   0 ## whole section or file
  DplElement = 1 ## each element of the outermost compound definition
  DplLine =    2 ## each element of the lowermost compound definition
                 ## separated by newlines

proc decode_file*(filename: string, dd: DatatypeDefinition,
                  skip_embedded_spec = false,
                  decoded_processor:
                    proc(decoded: JsonNode, data: pointer) = show_decoded,
                  decoded_processor_data: pointer = nil,
                  decoded_processor_level = DplWhole) =
  ##
  ## Decode a file applying a datatype definition and process the decoded data.
  ##
  ## What is passed to the processing function depends on the scope of the
  ## datatype definition and on the decoded_processor_level option:
  ## - scope line/unit: decoded line/unit
  ## - scope file/section, depends on decoded_processor_level:
  ##   - DplWhole: decoded data from whole file/section
  ##   - DplElement: decoded data from each element of the file/section
  ##                 compound definition
  ##   - DplLine: decoded line for each line (lines may be
  ##              hierarchically grouped into multiple levels of
  ##              compound definitions)
  ##
  let ddef = dd.dereference
  if ddef.scope == ddsUnit or ddef.scope == ddsLine:
    for decoded in decoded_lines_or_units(filename, ddef, skip_embedded_spec):
      decoded_processor(decoded, decoded_processor_data)
  elif decoded_processor_level == DplWhole:
    if ddef.scope == ddsFile:
      decoded_processor(decoded_whole_file(filename, ddef, skip_embedded_spec),
                        decoded_processor_data)
    else:
      for decoded in decoded_sections(filename, ddef, skip_embedded_spec):
        decoded_processor(decoded, decoded_processor_data)
  elif decoded_processor_level == DplElement:
    if ddef.scope == ddsFile:
      for decoded in decoded_whole_file_elements(
                       filename, ddef, skip_embedded_spec):
        decoded_processor(decoded, decoded_processor_data)
    else:
      for decoded in decoded_section_elements(
                       filename, ddef, skip_embedded_spec):
        decoded_processor(decoded, decoded_processor_data)
  else:
    if ddef.scope == ddsFile:
      decode_whole_file_lines(filename, ddef, decoded_processor,
                              decoded_processor_data, skip_embedded_spec)
    else:
      decode_section_lines(filename, ddef, decoded_processor,
                           decoded_processor_data, skip_embedded_spec)

iterator decoded_file*(filename: string, dd: DatatypeDefinition,
                       skip_embedded_spec = false, yield_elements = false):
                         JsonNode =
  ##
  ## Decode a file applying the specified definition and yield the decoded data.
  ##
  ## What is yielded at each iteration depends on the scope of the datatype
  ## definition, and by the yield_elements flag:
  ## - scope line/unit: decoded line/unit
  ## - scope file/section:
  ##   - by default: decoded data from whole file/section
  ##   - if "yield_elements" is set:
  ##     decoded data from each element of the file/section compound
  ##     definition
  ##   note: differently from the "decode_file" proc, there is no way to yield
  ##   the decoded single lines for scope file/section, because iterators
  ##   cannot be applied recursively, in the current Nim implementation.
  let ddef = dd.dereference
  if ddef.scope == ddsUnit or ddef.scope == ddsLine:
    for decoded in decoded_lines_or_units(filename, ddef, skip_embedded_spec):
      yield decoded
  elif yield_elements:
    if ddef.scope == ddsFile:
      for decoded in decoded_whole_file_elements(
                       filename, ddef, skip_embedded_spec):
        yield decoded
    else:
      for decoded in decoded_section_elements(
                       filename, ddef, skip_embedded_spec):
        yield decoded
  else:
    if ddef.scope == ddsFile:
      yield decoded_whole_file(filename, ddef, skip_embedded_spec)
    else:
      for decoded in decoded_sections(filename, ddef, skip_embedded_spec):
        yield decoded

