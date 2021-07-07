% TF\_SPEC(1) tf\_spec 1.0.0
% Giorgio Gonnella
% June 2021

# NAME

tf\_spec - tools for working with specification files

# SYNOPSIS

**tf\_spec** info -s SPECFILE [-t DATATYPE]\
**tf\_spec** preprocess -s SPECFILE -o OUTFILE\
**tf\_spec** generate\_tests -s SPECFILE [-f TESTFILE]\
**tf\_spec** test -s SPECFILE [-f TESTFILE]\

# DESCRIPTION

The command offers several tools for working with specification
files, which are YAML files, JSON files,
or preprocessed specifications
(which can be created with the command itself).

## Introspection

The command allows to list the datatypes contained in the file
(subcommand *list*) and to show the definition of one of those datatypes
(subcommand *show*).

## Preprocessing

A preprocessed version of the specification can be created
using the *preprocess* subcommand.
They can be used by most CLI commands instead of the YAML or JSON file.

Preprocessed specifications can be faster to load in some cases, compared
to the YAML or JSON specifications (which requires parsing and validation of the
content and generation of the regular expressions).

Only the datatype specifications are contained in the preprocessed
file, not the testdata and embedded data.
Preprocessed specifications cannot be provided from the standard input.

## Tests

The specification can be accompanied by examples of valid and invalid encoded
and decoded data (in YAML or JSON format). This test data can be included
in the same file as the specification or be written to a different file.

Examples for each of the datatypes in a specification can be automatically
generated using the *generate_tests* subcommand. The automatic generation
is based on the Python library exrex, which must be installed for this command
to work. It has limitations (i.e. does not generate examples for some of the
datatypes), but it is useful to check that the datatypes were defined as
expected.

If the automatically generated examples are edited and/or further examples
with expected results are added manually, the *test* subcommand can be
used to check that all tests succeed. The command runs decoding,
encoding and validations for each of the provided test examples.

# OPTIONS

## Subcommands

**list**
: list all definitions in a specification file

**show**
: show a definition in a specification file

**generate\_tests**
: auto-generate testdata for a specification file

**preprocess**
: preprocess a specification file

**test**
: test a specification using a testdata file

## Required options

all subcommands:

**-s**, **\-\-specfile=**FILENAME
: specification file to be used (default: standard input);
  YAML, JSON or preprocessed;
  preprocessed specifications can be used except for
  *preprocess* and *generate\_tests* and cannot be provided
  as standard input

*info* subcommand:

**-t**, **\-\-datatype=**DATATYPE
: specify a datatype, to show information about a datatype
  (default: display the list of datatypes defined by the specification)

*preprocess* subcommand:

**-o**, **\-\-outfile=**FILENAME
: output filename for the preprocessed specification
  (default: standard output)

## Further options

*test* subcommand:

**-f**, **\-\-testfile=**FILENAME
: file containing tests; this option must be used if the test data is in
a different file than the specification (default: the test data are contained
in the specification file)

*generate_tests* subcommand:

**-f**, **\-\-testfile=**FILENAME
: file containing tests; if this option is used, the command only generates
testdata of those datatypes for which tests are not yet available; the output
in this case is so formatted, that it can be appended to an existing
testdata YAML or JSON file (default: test data is generated for all datatypes
of the specification file or provided to the option \-\-datatypes)

**-t**, **\-\-datatypes=**DATATYPES
: specify one or multiple datatype names (comma separated, without spaces),
  to limit the output to those datatypes
  (default: test data is generated for all datatypes
   of the specification file)

# EXIT VALUES
The exit code is 0 on success, anything else on error.

