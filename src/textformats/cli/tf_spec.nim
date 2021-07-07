##
## Tools for working with specification files
##
## They allow listing datatypes, showing information about a datatype,
## preprocessing a specification, generating testdata and
## running the test suite.
##

import tables, strutils, sets, terminal
import ../testdata_generator, ../spec_parser, ../testdata_parser
import ../types/datatype_definition
import ../../textformats
import cli_helpers

proc preprocess*(specfile = "", outfile = ""): int =
  ## preprocess a specification file
  if isatty(stdin) and specfile == "":
    exit_with(ec_err_setting,
              "You must provide an input specification file as a " &
              "filename or standard input")
  preprocess_specification(specfile, outfile)
  exit_with(ec_success)

proc info*(specfile = "", datatype = ""): int =
  ## if no datatype is specified, list all definitions in a specification
  ## otherwise: show info about a definition
  if datatype == "":
    let datatypes = get_specification(specfile)
    for datatype_name, datatype in datatypes:
      if datatype_name notin textformats.BaseDatatypes:
        echo $datatype_name
  else:
    let definition = get_datatype_definition(specfile, datatype)
    echo definition.verbose_desc(0)
  exit_with(ec_success)

proc test*(specfile = "", testfile = ""): int =
  ## test a specification using a testdata file
  let datatypes = get_specification(specfile)
  let test_or_specfile =
    if len(testfile) == 0: specfile
    else: testfile
  try:
    datatypes.run_specification_testfile(test_or_specfile)
  except textformats.InvalidTestdataError, textformats.TestError:
    exit_with(ec_testerror, get_current_exception_msg(), false)
  exit_with(ec_success)

# not accepting preprocessed specifications because in the preprocessed
# there is no information if a datatype is defined in the specification
# itself or in an included file; thus list_specification_datatypes is only
# accepting a YAML/JSON specification
#
# if a testfile is provided, only datatypes not present in the testfile
# are considered, and the initial "testdata:" is not printed, so that
# the output can be appended to the input testfile
proc generate_tests*(specfile = "", testfile = "", datatypes = ""): int =
  ## auto-generate testdata for a specification file
  let specification = parse_specification_file(specfile)
  var to_generate = initHashSet[string]()
  if len(datatypes) > 0:
    for datatype in datatypes.split(','):
      to_generate.incl(datatype)
  else:
    for datatype in list_specification_datatypes(specfile):
      to_generate.incl(datatype)
  if len(testfile) > 0:
    for datatype in list_testdata_datatypes(testfile):
      to_generate.excl(datatype)
  else:
    echo "testdata:"
  for ddn in to_generate:
    echo specification[ddn].to_testdata(ddn)
  exit_with(ec_success)

when isMainModule:
  import cligen
  dispatch_multi(
                 [info,
                  short = {"specfile": short_specfile,
                           "datatype": short_datatype},
                  help = {"specfile": help_specfile,
                          "datatype": help_datatype_no_default}],
                 [generate_tests,
                  short = {"specfile": short_specfile,
                           "testfile": short_testfile,
                           "datatypes": short_datatypes},
                  help = {"specfile": help_specfile_yaml,
                          "testfile": help_opt_testfile,
                          "datatypes": help_datatypes}],
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
