##
## Tools for working with specification files
##
## They allow listing datatypes, showing information about a datatype,
## preprocessing a specification, generating testdata and
## running the test suite.
##

import tables, strutils, sets, streams
import ../testdata_generator, ../spec_parser, ../testdata_parser
import ../../textformats
import cli_helpers

proc show*(specfile: string, datatype: string): int =
  ## show a definition in a specification file
  let definition = get_datatype_definition(datatype)
  echo $definition
  exit_with(ec_success)

proc preprocess*(specfile: string, outfile: string): int =
  ## preprocess a specification file
  if specfile.is_preprocessed:
    exit_with(ec_err_preproc)
  let datatypes = parse_specification(specfile)
  datatypes.save_specification(outfile)
  exit_with(ec_success)

proc list*(specfile: string): int =
  ## list all definitions in a specification file
  let datatypes = get_specification(specfile)
  for datatype_name, datatype in datatypes:
    if datatype_name notin textformats.BaseDatatypes:
      echo $datatype_name
  exit_with(ec_success)

proc test*(specfile: string, testfile = ""): int =
  ## test a specification using a testdata file
  let datatypes = get_specification(specfile)
  let test_or_specfile =
    if len(testfile) == 0: specfile
    else: testfile
  try:
    datatypes.test_specification(test_or_specfile)
  except textformats.InvalidTestdataError, textformats.TestError:
    exit_with(ec_testerror, get_current_exception_msg(), false)
  exit_with(ec_success)

# not accepting preprocessed specifications because in the preprocessed
# there is no information if a datatype is defined in the specification
# itself or in an included file; thus list_specification_datatypes is only
# accepting a YAML specification
#
# if a testfile is provided, only datatypes not present in the testfile
# are considered, and the initial "testdata:" is not printed, so that
# the output can be appended to the input testfile
proc generate_tests*(specfile: string, testfile = ""): int =
  ## auto-generate testdata for a specification file
  if specfile.is_preprocessed:
    exit_with(ec_err_preproc)
  let
    datatypes = list_specification_datatypes(specfile)
    specification = parse_specification(specfile)
  let skip_datatypes =
    if len(testfile) > 0:
      toHashSet(list_testdata_datatypes(testfile))
    else:
      initHashSet[string]()
  if len(testfile) == 0:
    echo "testdata:"
  for ddn in datatypes:
    if ddn notin skip_datatypes:
      echo specification[ddn].to_testdata(ddn)
  exit_with(ec_success)

when isMainModule:
  import cligen
  dispatch_multi(
                 [list,
                  short = {"specfile": short_specfile},
                  help = {"specfile": help_specfile}],
                 [show,
                  short = {"specfile": short_specfile,
                           "datatype": short_datatype},
                  help = {"specfile": help_specfile,
                          "datatype": help_datatype}],
                 [generate_tests,
                  short = {"specfile": short_specfile,
                           "testfile": short_testfile},
                  help = {"specfile": help_specfile_yaml,
                          "testfile": help_opt_testfile}],
                 [preprocess,
                  short = {"specfile": short_specfile,
                           "outfile": short_outfile},
                  help = {"specfile": help_specfile_yaml,
                          "outfile": help_outfile}],
                 [test,
                  short = {"specfile": short_specfile,
                           "testfile": short_testfile},
                  help = {"specfile": help_specfile,
                          "testfile": help_testfile}])
