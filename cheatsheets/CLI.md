# Installation / nimble tasks

|                          |                                    |
| ------------------------ | ---------------------------------- |
Build the CLI tools        | `nimble build`
Path to the CLI tools      | `<TEXTFORMATS>/cli` (1)
Build the man pages        | `nimble climan`
Path to the man pages      | `<TEXTFORMATS>/cli/man` (1)
Run CLI test suite         | `nimble clitest`
Path to the test suite     | `<TEXTFORMATS>/tests/cli/test_cli.sh` (1)

(1): `<TEXTFORMATS>`: main directory of the TextFormats source code
repository

# Overview of the tools

|             |                                              |
| ----------- | -------------------------------------------- |
`tf_spec`     | handle TextFormats specification files
`tf_decode`   | from a text format (file or string) to JSON
`tf_encode`   | from JSON (string) to a text format
`tf_validate` | check if data (text format or JSON) respect a specification

# Common switches

|                            |                                 |
| -------------------------- | ------------------------------- |
`<TOOL> --help`              | list subcommands
`<TOOL> <SUBCOMMAND> --help` | list arguments/options of subcommand
`--specfile`/`-s`            | specification file (YAML/JSON or compiled)
`--datatype`/`-t`            | datatype to use (default: `default`)

# Encoding, decoding and validating data

|                       |                                      |
| --------------------- | ------------------------------------ |
Encode JSON data        | `tf_decode json -d <JSON> -s <SPECFILE> -t <DATATYPE>` (1) (2)
Validate JSON data      | `tf_validate decoded -d <STRING> -s <SPECFILE> -t <DATATYPE>` (1) (2)
Decode string in text format | `tf_decode string -e <STRING> -s <SPECFILE> -t <DATATYPE>` (1) (2)
Validate string in text format | `tf_validate encoded -e <STRING> -s <SPECFILE> -t <DATATYPE>` (1) (2)
Decode file in text format  | `tf_decode file -i <INFILE> -s <SPECFILE> -t <DATATYPE>` (1) (2)
" using spec embedded in datafile | `tf_decode file -i <INFILE> -t <DATATYPE>` (1) (3)
" using line/section/file scope  | `... --scope line/section/file`
" using unit scope  | `... --scope unit --unitsize <I>`
" each line in section/file scope | `... --scope section/file --splitted`
" show branch information if datatype is `one_of` | `... --wrapped`

(1): `-t` option can be omitted if datatype is called `default`
(2): input data can be provided as standard input (instead of `-d`/`e`/`-i` switch)
(3): no `-s` option used; data file cannot be provided as standard input

# Data which can be passed as standard input

|                            |                                 |
| -------------------------- | ------------------------------- |
`tf_decode string` | data to decode from text format to JSON
`tf_decode file`  | file to decode from text format to JSON
`tf_encode json`   | JSON data to encode to text format
`tf_validate decoded` | JSON data to validate
`tf_validate encoded` | data in text format to validate
`tf_spec` | specification (not compiled)

# Operations on specifications

|                                  |                                      |
| -------------------------------- | ------------------------------------ |
List datatypes                     | `tf_spec info`
Info on a datatype (verbose)       | `tf_spec info -t <DT>`
Info on a datatype (tabular)       | `tf_spec info -t <DT> -k tabular`
Show datatype definition           | `tf_spec info -t <DT> -k repr`
Compile (to std output)            | `tf_spec compile`
Compile (to file)                  | `tf_spec compile --outfile <FN.tfs>`
Run specification tests (embedded) | `tf_spec test`
Run specification testfile         | `tf_spec test -t <TESTFILE>`
Generate examples / testdata (1)       | `tf_spec generate_tests`
" consider included specifications (2) | `tf_spec generate_tests --included`
" only for specified datatypes         | `tf_spec generate_tests -t <DT1>,<DT2>,...`
" only datatype not yet in testfile | `tf_spec generate_tests -f <TESTFILE>`

(1) Python library `exrex` must be installed, binary `exrex` must be in PATH
(2) default behaviour for compiled specifications and specifications
    passed as standard input

