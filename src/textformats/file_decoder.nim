import strutils, strformat, options, json
import decoder
import types / [datatype_definition, textformats_error, file_lines_reader]

proc decode_section*(reader: var FileLinesReader,
                     dd: DatatypeDefinition): JsonNode

proc decode_section_lines*(reader: var FileLinesReader,
                           dd: DatatypeDefinition, key: string,
                           line_processor: proc(decoded_line: JsonNode))

import dt_list/list_file_decoder
import dt_struct/struct_file_decoder
import dt_dict/dict_file_decoder
#import dt_tags/tags_file_decoder

template open_input_file(filename: string): File =
  var file: File = nil
  try: file = open(filename)
  except IOError:
    let e = getCurrentException()
    raise newException(TextformatsRuntimeError,
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
                       embedded = false, wrapped = false,
                       unitsize = 1): JsonNode =
  assert unitsize >= 1
  let file = open_input_file(filename)
  var ddef = dereference(dd)
  if wrapped and dd.kind == ddkUnion:
    ddef.wrapped = true
  var
    line_no = 0
    state = dps_init(embedded)
    linesgroup = newseq[string](unitsize)
    n_in_group = 0
    shall_decode = true
  for line in lines(file):
    line_no += 1
    case state:
    of dpsData:
      if unitsize > 1:
        linesgroup[n_in_group] = line
        n_in_group += 1
        shall_decode = (n_in_group == unitsize)
      if shall_decode:
        try:
          if unitsize > 1:
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
  if n_in_group > 0:
    raise newException(DecodingError,
                       &"File: '{filename}'\n" &
                       "Final group of lines does not contain enough lines\n" &
                       &"Found n. of lines: {n_in_group}\n" &
                       &"Required n. of lines: {unitsize}")

iterator decoded_lines*(filename: string, dd: DatatypeDefinition,
                        embedded = false, wrapped = false): JsonNode =
  ## Decode a file applying the definition dd to each line independently
  ##
  ## Options:
  ##
  ## - embedded: (bool, default: false) if true, the file is assumed to
  ##             contain an embedded specification before the data, which is
  ##             then skipped; i.e. only the content after the first document
  ##             separator "---" is decoded
  ##
  ## - wrapped: (bool, default: false) if true and dd.kind == ddkUnion
  ##            (or ddkRef targeting a ddkUnion), then the wrapped flag of dd
  ##            is set, i.e. the type information is added to the
  ##            result; if any other kind of definition, or if the wrapped
  ##            flag of the union was already set, then the option is ignored
  ##
  for decoded in decoded_lines_or_units(filename, dd, embedded, wrapped):
    yield decoded

iterator decoded_units*(filename: string, dd: DatatypeDefinition, unitsize: int,
                        embedded = false, wrapped = false): JsonNode =
  ## Decode a file applying the definition dd to each unit, i.e. group
  ## of a constant number of lines, independently
  ##
  ## Options:
  ##
  ## - embedded: (bool, default: false) if true, the file is assumed to
  ##             contain an embedded specification before the data, which is
  ##             then skipped; i.e. only the content after the first document
  ##             separator "---" is decoded
  ##
  ## - wrapped: (bool, default: false) if true and dd.kind == ddkUnion
  ##            (or ddkRef targeting a ddkUnion), then the wrapped flag of dd
  ##            is set, i.e. the type information is added to the
  ##            result; if any other kind of definition, or if the wrapped
  ##            flag of the union was already set, then the option is ignored
  ##
  ## - unitsize: (int > 1) number of lines to decode at once
  ##
  for decoded in decoded_lines_or_units(filename, dd, embedded, wrapped,
                                        unitsize=unitsize):
    yield decoded

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
                           line_processor: proc(decoded_line: JsonNode)) =
  let ddef = dereference(dd)
  on_section_def(ddef):
    case ddef.kind:
    of ddkStruct:
      reader.decode_struct_section_lines(ddef, key, line_processor)
    of ddkList:
      reader.decode_list_section_lines(ddef, key, line_processor)
    of ddkDict:
      reader.decode_dict_section_lines(ddef, key, line_processor)
    #of ddefkTags:
    #  reader.decode_tags_section_lines(ddef, key, line_processor)
    else: assert(false)
  do:
    var obj = newJObject()
    obj[key] = reader.line.decode(ddef)
    line_processor(obj)

iterator decoded_section_elements*(reader: var FileLinesReader,
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
  if dd.kind != ddkStruct:
    raise newException(TextformatsRuntimeError,
            "Wrong datatype definition for file section\n" &
            "Expected: structure (kind: ddkStruct)\n" &
            &"Found: '{dd.kind}'")
  if dd.sep != "\n":
    raise newException(TextformatsRuntimeError,
            "Wrong separator for file section definition\n" &
            "Expected: newline\n" &
            &"Found: '{dd.sep}'")
  if dd.pfx.len > 0:
    raise newException(TextformatsRuntimeError,
            "Wrong prefix for file section definition\n" &
            "Expected: empty string\n" &
            &"Found: '{dd.pfx}'")
  if dd.sfx.len > 0:
    raise newException(TextformatsRuntimeError,
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

iterator decoded_sections*(filename: string, dd: DatatypeDefinition,
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

proc decoded_whole_file*(filename: string, dd: DatatypeDefinition,
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

proc decode_section_lines*(filename: string, dd: DatatypeDefinition,
                           line_processor: proc(decoded_line: JsonNode),
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
    reader.decode_section_lines(ddef, "", line_processor)

proc decode_whole_file_lines*(filename: string, dd: DatatypeDefinition,
                              line_processor: proc(decoded_line: JsonNode),
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
    reader.decode_section_lines(ddef, "", line_processor)

iterator decoded_section_elements*(filename: string, dd: DatatypeDefinition,
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

iterator decoded_whole_file_elements*(filename: string, dd: DatatypeDefinition,
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

proc parse_scope_setting*(scope: string, dd: DatatypeDefinition):
                          DatatypeDefinitionScope =
  ##
  ## Compute the scope of a definition given a scope setting parameter (string)
  ##
  ## The scope setting parameter must be either one of the scope values
  ## (whole, section, unit, line) or "auto". In the latter case, the
  ## scope must be defined in the datatype definition.
  ##
  let valid_definition_types = @["whole", "section", "unit", "line", "auto"]
  if scope notin valid_definition_types:
    let scope_errmsg = block:
      var msg = "Error: scope must be one of the following values:\n"
      for t in valid_definition_types:
        msg &= &"- {t}\n"
      msg
    raise newException(TextformatsRuntimeError, scope_errmsg)
  case scope:
  of "whole": return ddsWhole
  of "section": return ddsSection
  of "unit": return ddsUnit
  of "line": return ddsLine
  of "auto":
    let ddef = dereference(dd)
    if ddef.scope == ddsUndef:
      raise newException(TextformatsRuntimeError,
         "Error: scope 'auto' requires a " &
         "'scope' key in the datatype definition")
    return ddef.scope

proc parse_unitsize_setting*(unitsize: int, dd: DatatypeDefinition): int =
  ##
  ## Compute the unit size of a definition given a setting parameter (int)
  ##
  ## If the unitsize setting parameter is 1, then the value is taken
  ## from the datatype definition (which must define it, in this case);
  ## otherwise the setting is used.
  ##
  let
    wrong_value_msg =
        "The unitsize parameter for the scope 'unit' must be > 1"
  if unitsize < 1:
    raise newException(TextformatsRuntimeError, wrong_value_msg)
  elif unitsize == 1:
    let ddef = dereference(dd)
    if ddef.unitsize > 1:
      return ddef.unitsize
    else:
      raise newException(TextformatsRuntimeError,
                         wrong_value_msg)
  return unitsize

proc show_decoded(decoded: JsonNode) = echo $decoded

proc decode_file*(filename: string, dd: DatatypeDefinition, embedded = false,
                  scope = "auto", linewise = false, wrapped = false,
                  unitsize = 1,
                  process_decoded: proc(decoded: JsonNode) = show_decoded) =
  ##
  ## Decode a file applying the specified definition
  ##
  let
    scope_param = scope.parse_scope_setting(dd)
    unitsize_param =
      if scope_param == ddsUnit: parse_unitsize_setting(unitsize, dd)
      else: 1
  if scope_param == ddsUnit or scope_param == ddsLine:
    for decoded in decoded_lines_or_units(filename, dd, embedded, wrapped,
                                          unitsize_param):
      process_decoded(decoded)
  elif linewise:
    if scope_param == ddsWhole:
      decode_whole_file_lines(filename, dd, process_decoded, embedded)
    else:
      decode_section_lines(filename, dd, process_decoded, embedded)
  else:
    if scope_param == ddsWhole:
      process_decoded(decoded_whole_file(filename, dd, embedded))
    else:
      for decoded in decoded_sections(filename, dd, embedded):
        process_decoded(decoded)

iterator decoded_file_values*(filename: string, dd: DatatypeDefinition,
                  embedded = false, scope = "auto", elemwise = false,
                  wrapped = false, unitsize = 1): JsonNode =
  ##
  ## Decode a file applying the specified definition
  ##
  let
    scope_param = scope.parse_scope_setting(dd)
    unitsize_param =
      if scope_param == ddsUnit: parse_unitsize_setting(unitsize, dd)
      else: 1
  if scope_param == ddsUnit or scope_param == ddsLine:
    for decoded in decoded_lines_or_units(filename, dd, embedded, wrapped,
                                          unitsize_param):
      yield decoded
  elif elemwise:
    if scope_param == ddsWhole:
      for decoded in decoded_whole_file_elements(filename, dd, embedded):
        yield decoded
    else:
      for decoded in decoded_section_elements(filename, dd, embedded):
        yield decoded
  else:
    if scope_param == ddsWhole:
      yield decoded_whole_file(filename, dd, embedded)
    else:
      for decoded in decoded_sections(filename, dd, embedded):
        yield decoded

