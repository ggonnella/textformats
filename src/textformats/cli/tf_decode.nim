##
## Decode a textual representation to the corresponding data,
## according to a given datatype from a specification
##
## The input is the textual representation, either as a string
## or as a file in a given format
##
## The output is the decoded data, represented as JSON.
##

import tables, strutils, json, strformat
import ../../textformats
import ../types/datatype_definition
import cli_helpers

proc decode_string*(specfile: string, datatype = "default",
                 encoded: string): int =
  ## decode an encoded string and output as JSON
  let definition = get_datatype_definition(specfile, datatype)
  try:
    echo $textformats.decode(encoded, definition)
  except textformats.DecodingError:
    exit_with(ec_err_invalid_encoded, getCurrentExceptionMsg())

proc parse_scope(scope: string, dd: DatatypeDefinition):
                 DatatypeDefinitionScope =
  let valid_definition_types = @["whole", "section", "unit", "line", "auto"]
  if scope notin valid_definition_types:
    let scope_errmsg = block:
      var msg = "Error: scope must be one of the following values:\n"
      for t in valid_definition_types:
        msg &= &"- {t}\n"
      msg
    raise newException(textformats.TextformatsRuntimeError, scope_errmsg)
  case scope:
  of "whole": return ddsWhole
  of "section": return ddsSection
  of "unit": return ddsUnit
  of "line": return ddsLine
  of "auto":
    let ddef = dereference(dd)
    if ddef.scope == ddsUndef:
      raise newException(textformats.TextformatsRuntimeError,
         "Error: scope 'auto' requires a " &
         "'scope' key in the datatype definition")
    return ddef.scope

let
  not_whole_msg =
      "Error: the specified datatype definition applies " &
      "only to part of the file\n" &
      "Expected: definition applying to the whole file\n"

proc parse_unitsize(unitsize: int, scope: DatatypeDefinitionScope,
                    dd: DatatypeDefinition): int =
  let
    wrong_scope_msg =
        "The unitsize parameter is only used for the unit scope"
    wrong_value_msg =
        "The unitsize parameter for the scope 'unit' must be > 1"
  if scope == ddsUnit:
    if unitsize < 1:
      raise newException(textformats.TextformatsRuntimeError, wrong_value_msg)
    elif unitsize == 1:
      let ddef = dereference(dd)
      if ddef.unitsize > 1:
        return ddef.unitsize
      else:
        raise newException(textformats.TextformatsRuntimeError,
                           wrong_value_msg)
  else:
    if unitsize != 1:
      raise newException(textformats.TextformatsRuntimeError, wrong_scope_msg)
  return unitsize

proc decode_file*(specfile = "", datatype = "default", infile: string,
                  scope = "auto", linewise = false,
                  wrapped = false, unitsize = 1): int =
  ## decode a file, given a datatype definition
  let
    embedded = (specfile == "")
    specsrc = block:
      if embedded:
        fail_if_preprocessed(infile)
        infile
      else:
        specfile
    definition = get_datatype_definition(specsrc, datatype)
  let
    scope_param = scope.parse_scope(definition)
    unitsize_param = parse_unitsize(unitsize, scope_param, definition)
  var first_section = true
  try:
    if scope_param == ddsUnit or scope_param == ddsLine:
      for decoded in textformats.decoded_lines(infile, definition,
                       embedded, wrapped, unitsize_param):
        echo decoded
    elif linewise:
      proc show_decoded_line(decoded: JsonNode) =
        echo decoded
      textformats.decode_file_section_lines(infile, definition,
                                            show_decoded_line,
                                            scope_param == ddsWhole,
                                            embedded)
    else:
      for decoded in textformats.decoded_file_sections(infile, definition,
                       embedded=embedded):
        if scope_param == ddsWhole:
          if not first_section:
            exit_with(ec_err_invalid_encoded, not_whole_msg)
          first_section = false
        echo decoded
  except textformats.DecodingError:
    exit_with(ec_err_invalid_encoded, getCurrentExceptionMsg())

when isMainModule:
  import cligen
  dispatch_multi([decode_string, cmdname = "string",
                  short = {"specfile": short_specfile,
                           "datatype": short_datatype,
                           "encoded":  short_encoded},
                  help = {"specfile": help_specfile,
                          "datatype": help_datatype,
                          "encoded":  help_encoded}],
                 [decode_file, cmdname = "file",
                  short = {"specfile": short_specfile,
                           "datatype": short_datatype,
                           "infile":  short_infile,
                           "scope": short_scope,
                           "linewise": short_linewise,
                           "wrapped": short_wrapped,
                           "unitsize": short_unitsize},
                  help = {"specfile": help_specfile_or_embedded,
                          "datatype": help_datatype,
                          "infile":  help_infile,
                          "scope": help_scope,
                          "linewise": help_linewise,
                          "wrapped": help_wrapped,
                          "unitsize": help_unitsize}])
