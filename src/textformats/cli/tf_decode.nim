##
## Decode a string representation to the corresponding data,
## according to a given datatype from a specification
##
## The input is the string representation, either as the string itself
## or as a file in a given format
##
## The output is the decoded data, represented as JSON.
##

import tables, strutils, json, terminal
import ../../textformats
import cli_helpers

proc decode_string*(specfile: string, datatype = "default",
                    encoded = ""): int =
  ## decode an encoded string and output as JSON
  let to_decode = str_or_stdin(encoded)
  let definition = get_datatype_definition(specfile, datatype)
  try:
    echo $textformats.decode(to_decode, definition)
  except textformats.DecodingError:
    exit_with(ec_err_invalid_encoded, getCurrentExceptionMsg())

proc parse_scope_setting*(scope: string, dd: DatatypeDefinition): int =
  ##
  ## Compute the scope of a definition given a scope setting parameter (string)
  ##
  ## The scope setting parameter must be either one of the scope values
  ## (file, section, unit, line) or "auto". In the latter case, the
  ## scope must be defined in the datatype definition.
  ##
  if scope == "auto":
    if dd.get_scope == "undefined":
      exit_with(ec_err_setting,
         "Error: if no scope is provided (or is set to 'auto') a " &
         "'scope' key must be provided in the datatype definition")
  else:
    try:
      dd.set_scope(scope)
    except TextFormatsRuntimeError:
      exit_with(ec_err_setting,
                get_current_exception_msg() & "- auto\n")
  return 0

proc parse_unitsize_setting*(unitsize: int, dd: DatatypeDefinition): int =
  ##
  ## Compute the unit size of a definition given a setting parameter (int)
  ##
  ## If the unitsize setting parameter is 1, then the value is taken
  ## from the datatype definition (which must define it, in this case);
  ## otherwise the setting is used.
  ##
  if unitsize < 1:
    exit_with(ec_err_setting, "The 'unitsize' parameter must be >= 1")
  elif unitsize == 1 and dd.get_scope == "unit":
    if dd.get_unitsize > 1: return
    else:
      exit_with(ec_err_setting,
                "The 'unitsize' parameter for the scope 'unit' must be > 1")
  else:
    dd.set_unitsize(unitsize)
  return 0

proc decode_datafile*(specfile = "", datatype = "default", infile = "",
                      scope = "auto", splitted = false, wrapped = false,
                      unitsize = 1): int =
  ## decode a file, given a datatype definition
  let
    skip_embedded_spec = (specfile == "")
    specsrc = block:
      if skip_embedded_spec:
        if infile == "":
          exit_with(ec_err_setting,
                    "Please provide at least either the name of the " &
                    "specification file or of the input data file\n" &
                    "Specifications cannot be skip_embedded_spec in the " &
                    "standard input")
        fail_if_compiled(infile)
        infile
      else:
        specfile
    definition = get_datatype_definition(specsrc, datatype)
  var ec: int
  ec = parse_scope_setting(scope, definition)
  if (ec != 0): return ec
  ec = parse_unitsize_setting(unitsize, definition)
  if (ec != 0): return ec
  let level = if splitted: DplWhole else: DplLine
  try:
    if wrapped:
      definition.set_wrapped()
    decode_file(infile, definition, skip_embedded_spec,
                  decoded_processor_level = level)
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
                 [decode_datafile, cmdname = "file",
                  short = {"specfile": short_specfile,
                           "datatype": short_datatype,
                           "infile":  short_infile,
                           "scope": short_scope,
                           "splitted": short_splitted,
                           "wrapped": short_wrapped,
                           "unitsize": short_unitsize},
                  help = {"specfile": help_specfile_or_embedded,
                          "datatype": help_datatype,
                          "infile":  help_infile,
                          "scope": help_scope,
                          "splitted": help_splitted,
                          "wrapped": help_wrapped,
                          "unitsize": help_unitsize}])
