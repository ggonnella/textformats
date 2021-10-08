# Command line interface

TextFormats can be accessed using a set of command line tools. These are build
using the command `nimble build` from the main directory of the TextFormats
source code and are then contained in the `cli` subdirectory.

## Tools

There are four command line tools:
- `tf_spec`: handling of TextFormats specification files
- `tf_decode`: extracting data from a file or a string in a given format
described by a TextFormats specification into JSON
- `tf_encode`: convert a string containing JSON data to a given format
described by a TextFormats specification
- `tf_validate`: check if a given string representation, or decoded data
(passed as JSON) is compatible to a format described by a TextFormats
specification.

## Help

Each tool has subcommand: their list is output by `<toolname> --help`.
The mandatory and optional arguments of each subcommand are output by
`<toolname> <SUBCOMMAND> --help`.

## Man pages

Besides this documentation, manual pages (for the Posix tool `man`) are also
available. They are generated using the command `nimble climan` from the main
directory of the TextFormats source code and are then contained in the
`cli/man` subdirectory.

## CLI Tests

A test suite for the CLI tools is available in the directory `tests/cli`
and is executed using the command `nimble clitest` from the main directory
of the TextFormats source code. Its source code (`test_cli.sh`)
shows example usages of most encoding, decoding and validation
operations possible with the command line interface.

## Specifications

For most applications, a TextFormats specification is necessary. This can
be selected in the tools interface using the `--specfile`/`-s` option.
The specification can be JSON/YAML or compiled.
For `tf_spec` only, the specification can be passed as standard input
(but only if not compiled).

The tool `tf_spec` is used for performing operations
on specification files.

### List of datatype names

To output the names of the datatypes defined by a specification,
the `tf_spec info` command is used, without setting the
`--datatype`/`-t` option.

### Compilation

It is possible to compile a YAML specification using the tool
`tf_spec compile`. The output of the tool (compiled
specification) is by default written to the standard output; in alternative
a filename can be provided using the option `--outfile`.
The suggested file extension for compiled specifications
is `tfs` (*T*ext*F*ormats *S*pecification).

Compiled specifications can be used in most tools in place
of the YAML specifications and are automatically
recognized.

A limitation of compiled specifications is that they cannot
contain test data or be embedded in data files.
Furthermore, they cannot be provided as standard input to the
`tf_spec` tool.

### Running tests

It is possible to run a test suite for a specification using the
command `tf_spec test`.
The path to the specification file is provided through
the option `--specfile` or `-s`.

The path to the file containing the tests is provided through
the option `--testfile` or `-t`. Test data can also be contained
in the specification, in which case this option is not
necessary. Compiled specifications do not contain
the test data, so the option is always required in that case.

### Generating data according to the definitions

It is possible to generate data which follows the definitions given
in a specification using the `tf_spec generate_tests` command.

Both valid and invalid data are generally
generated. Data generation requires the installation of the
python library `exrex` (e.g. using `pip`) and that the
`exrex` binary is in path.

The automatically generated examples can be manually inspected
to check the provided definitions. They can be also useful
as a starting point in writing tests for a specification.

Thus the output of the tool is in the format required
for the specification test suite, which can be run using the command
`tf_spec test`.

By default, examples are provided for each of the datatypes
in the specification. Datatypes defined in included specifications
are not considered (except if `--included` is used, or if a compiled
file is used, or the specification is piped into the tool).
Alternatively, a comma-separated list of datatypes can be provided using
the option `--datatypes` or `-t` (e.g. `datatype1,datatype2,datatype3`).

Furthermore, if an existing testfile is provided using the option `--testfile`
or `-f`, only datatypes not yet present in the testfile are
used. This can be used for complementing a test file after
new definitions are added to a specification.

## Datatype definitions

The datatype definition is selected in the tools using the
`--datatype` or `-t` option. If the option is not provided,
the definition named `default` is used (if it exists).

A description of a datatype definition can be output
using the tool `tf_spec info` and providing the definition
name with the option `--datatype` or `-t` (even for `default`).
The style of the description is by default `verbose`;
other styles (`tabular` or `repr`) can be selected
using the option `--kind`.

## Decoding the string representation of data

The `string` subcommand of the `tf_decode` tool
decodes the input string, provided from the
standard input or using the option `--encoded` or `-e`.

The path to the specification file is provided through
the option `--specfile` or `-s`.

The datatype to be used for
decoding is selected using the `--datatype` or `-t` (if not provided,
the datatype named `default` is used).

The output of the command is the JSON representation of the
decoded data.

## Encoding data to their string representation

To encode data (represented as a JSON string) to an encoded representation
according to a given datatype definition, the `tf_encode json`
command is used.

The input string is a JSON representation of
the data to encode and is provided from the standard input or
using the option `--decoded_json` or `-d`.

The path to the specification file is provided through the option `--specfile`
or `-s`. The datatype to be used for
encoding is selected using the `--datatype` or `-t`.
(if not provided, the datatype named `default` is used).

## Validating data or their string representation

If is only necessary to know if encoded or decoded data follow a
datatype definition, and no access to the result of decoding or encoding is
necessary, the validation commands can be used. Depending on the datatype
definition, they can be faster than full decoding or encoding.

The `tf_validate` tool is used for validation. In particular the
command `tf_validate encoded` is used to validate an encoded string,
which is provided from the standard input or using
the option `--encoded` or `-e`. The command `tf_validate decoded`
is used to validate decoded data
provided in JSON format from the standard input or
using the option `--decoded_json` or `-d`.

The path to the specification file is provided through the option `--specfile`
or `-s`. The datatype to be used for
encoding is selected using the `--datatype` or `-t`.
(if not provided, the datatype named `default` is used).

## Decoding a file

The `file` subcommand of the `tf_decode` tool
decodes the input file, provided from the
standard input or using the option `--infile` or `-i`.

The path to the specification file is provided through
the option `--specfile` or `-s`; if the specification is embedded
in the datafile, this option shall not be used (see below).
The datatype to be used for
decoding is selected using the `--datatype` or `-t` (if not provided,
the datatype named `default` is used).

The output of the command is the JSON representation of each of the
decoded values obtained from the file.

### Embedded specifications

Data and the specification may be contained in the same file. The data
file may contain an embedded YAML specification, preceding the data and
separated from it by a YAML document separator line (`---`).
In this case, the option `--specfile` is not set.

Data files with embedded specifications cannot be provided
as standard input.

### Scope of the definition

In order to use a definition for decoding a file, a scope must be provided.
This determines which part of the file shall be decoded applying the definition.
The scope can be provided directly in the datatype definition and must be
"line", "unit" (constant number of lines), "section" (part of the file, as long
as possible, following a definition; greedy) or "file".
The scope of a definition can also be set using the parameter `--scope SCOPE`,
where `SCOPE` is "line", "unit", "section", or "file".

If the scope is set to `unit`, the number of lines of a unit must be set,
either in the datatype definition or using `--unitsize I` parameter
where `I` is an integer larger than 1.

## Splitted processing

Definitions at `file` or `section` scope are compound datatypes
(`composed_of`, `list_of` or `named_values`), which consist of multiple
elements (each in one or multiple lines).

If the flag `--splitted` or `-x` of
`tf_decode file` is set, the values yielded by the iterator are not the entire
data in the file section or whole file, but instead the single elements of
the compound datatype.

This is more efficient in the case of
large files, since it is not necessary to represent in memory and process
the entire file or file section at once.

### Reporting the branch of "one of" used by decoding

When a `one_of` definition is used for decoding, it is possible to set the
decoded value to contain information about which branch was used for the
decoding. This can be set either setting the key `wrapped` in the
datatype definition, or by setting the flag `--wrapped` of
`tf_decode file`.
