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
  let
    ddef = dereference(dd)
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

template onDataLines(reader, ddef, actions: untyped) =
  var state = dps_init(embedded)
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
      actions

iterator decoded_sections*(filename: string, dd: DatatypeDefinition,
                           embedded=false): JsonNode =
  ##
  ## Decode a file as a list of multiline units.
  ##
  ## Each of the units is defined by the passed datatype definition,
  ## as a multiline unit, i.e. a ddkStruct definition (or a reference to it)
  ## with a "\n" separator, and no pfx or sfx.
  ##
  ##
  ## Decode a file section (or entire file) using a definition for a compound
  ## datatype with newline as element separator, which describes its entire
  ## content, consisting of multiple lines.
  ##
  ## This is targeted at sections of a file, consisting of multiple lines,
  ## where the number of lines is not known in advance.
  ##
  ## This function returns the entire content of the file (or file section) at
  ## once. For large files decoded_section_lines can be more efficient.
  ##
  let
    ddef = dereference(dd)
    file = open_input_file(filename)
  var reader = new_file_lines_reader(file)
  onDataLines(reader, ddef):
    yield reader.decode_section(ddef)

proc decode_section_lines*(filename: string, dd: DatatypeDefinition,
                           line_processor: proc(decoded_line: JsonNode),
                           whole=false, embedded=false) =
  ##
  ## Decode a file using a definition which defines the entire
  ## structure of the file (or file section, see decode_by_unit_definition)
  ## as a compound datatype with newline as separator.
  ##
  ## This function passes each of the lines to the line_processor.
  ## For a similar function returning the decoded compound value
  ## see decode_by_file_def.
  ##
  ## The function pointer argument is used, since the function cannot be
  ## implemented as iterator because recursive iterators are not available in
  ## Nim.
  ##
  let
    ddef = dereference(dd)
    file = open_input_file(filename)
  var
    reader = new_file_lines_reader(file)
    section = 0
  onDataLines(reader, ddef):
    if whole and section > 0:
      raise newException(DecodingError,
         "Error: Datatype definition applies to a section of the file only" &
         &"Filename: {filename}\n" &
         "Expected: datatype definition for whole file\n" &
         &"Last line number of file section: {reader.lineno}")
    reader.decode_section_lines(ddef, "", line_processor)
    section += 1

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

let
  not_whole_msg =
      "Error: the specified datatype definition applies " &
      "only to part of the file\n" &
      "Expected: definition applying to the whole file\n"

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
  var first_section = true
  if scope_param == ddsUnit or scope_param == ddsLine:
    for decoded in decoded_lines_or_units(filename, dd, embedded, wrapped,
                                          unitsize_param):
      process_decoded(decoded)
  elif linewise:
    decode_section_lines(filename, dd, process_decoded,
                         scope_param == ddsWhole, embedded)
  else:
    for decoded in decoded_sections(filename, dd, embedded):
      if scope_param == ddsWhole:
        if not first_section:
          raise newException(DecodingError, not_whole_msg)
        first_section = false
      process_decoded(decoded)

