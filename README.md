# TextFormats

## Purpose

TextFormats is a library for rapidly defining and using text formats
for structured data.

Given a format definition in a simple declarative language (TF-Spec),
the library provides functions for switching
from the textual representation of data ("encoded string") to the actual
data which the text represents ("decoded data") and vice-versa.

The library aims at allowing rapid prototyping of libraries for supporting
file formats in Nim, C and Python, by providing base functionality,
on which further operations can be added. Furthermore, the definition
of the formats in TF-Spec is human readable and reduces the requirement
of complex regular expression. Finally, as opposed to lexers or regular
expressions, it does not only validates and splits different parts of a
format, but converts them to data in built-in scalar and compound datatypes,
allowing for fine tuning of the conversion.

The library, implemented in the programming language Nim, can be easily
accessed and employed in programs and scripts written in Nim, Python and C/C++,
or using the provided command line tools.

# An example

In multiple biological sequence analysis formats (e.g. SAM, GFA),
a CIGAR string represents a list of multi-edit operations, each consisting
of a length (positive integer value) and an operation code (one among a short
list of possible codes).

A textual representation of a CIGAR is for example
"10M1D20M1I40M". The string compactly represents a list of mappings,
each with two members "length" and "code". In JSON its representation would
be: [{length: 10, code: "M"}, {length: 1, code: "D"}, {length: 20, code: "M"},
{length: 1, code: "I"}, {length: 40, code: "M"}].

The definition of a CIGAR in TextFormats would be:
```
cigar:
  list_of:
    composed_of:
    - length: {unsigned_integer: {min: 1}}
    - code: {values: [M, D, I, P] }
```

Once the definition is provided, the library provides the following functions:
```
# decoding: textual representation => data
"10M1D".decode(cigar)
# => [{length: 10, code: "M"}, {length: 1, code: "D"}]

# encoding: data => textual representation
[{length: 10, code: "M"}, {length: 1, code: "D"}].encode(cigar)
# => "10M1D"

# validation of textual representation
"10M1D".is_valid(cigar)
# => true

# validation of data
[{length: 10, code: "M"}, {length: 1, code: "D"}].is_valid(cigar)
# => true
```

Furthermore, definitions can refer to each other, which allows splitting
a complex definition into smaller parts, and reuse them in different contexts.
For example, the previous definition could have been written as:
```
cigar_code: {values: [M, D, I, P]}
pos_integer: {unsigned_integer: {min: 1}}
cigar_op: {composed_of: [length: pos_integer, code: cigar_code]}
cigar: {list_of: cigar_op}
```

Since definitions can be re-used in different contexts and formats, they
can be stored in modules, which can be imported from other specification files.
The import mechanism is flexible, featuring namespaces, partial imports and
redefinitions of parts of an imported module.

Finally, sometimes fine tuning of the conversion between encoded and
decoded data is necessary. Thus, the following operations can be included
in the definitions:
- providing more meaningful strings:
e.g. in the example above of cigar operation code, one can
decode the "M" to the string "replacement" and the "D" to "deletion"
- converting to different types:
e.g. in some formats the symbols "+" and "-" represent
the boolean values true and false, and should be converted accordingly
- add implicit values:
e.g. in many formats, in a particular context
of the file, multiple kind of information can be stored, and can be recognized
from their different formatting; in this case, one
can add a label to the decoded data, describing the type of information
- remove formatting symbols:
often structured elements contain formatting constant strings such
as separators, prefixes and suffixes, which must not be included in the
resulting decoded data
- define default values:
sometimes a given symbol or part of a textual representation is missing
when representing a default value.

## Defining a format

In TextFormats, formats are defined in a specification file, which is written
in a human-readable YAML format or is created automatically using the provided
interactive command-line format description generator.

Once a text format is defined, its specification can be tested.
Random examples of each data type described in the format are automatically
created. The user can also provide other examples of string representations
and corresponding decoded data. These examples are used for automatically
test the specification.

## Implementation

The library is implemented using the programming language Nim.
This language was used, since it combines some of the advantages of Python
with those of compiled languages.

During compilation, C code is created and then compiled to binary.
Besides in Nim code itself, the resulting library can be easily employed
in C/C++ and in Python.

## Documentation

Under the directory `manuals` are the following documents, in Markdown
format:

`specifications.md`
: Describes the syntax of TextFormats specifications, which
are used to describe to the library all components of a format.
It contains a systematic list of the specification syntax, as
well as many examples.
`spec_howto_by_valuekind.md`
: Howto document, which explains how to define text representations
for different kind of values: strings, numeric, boolean, list, dictionaries, etc
`specification_tests.md`
: Specification test data are examples used to be sure that the format
specification reflects the expectations. This document describes
the syntax of test data and explains how to run tests.
`Nim_API.md`
: Describes the API of the TextFormats library in the Nim programming language
(in which the library is implemented)
`Python_API.md`
: Describes the API of the wrapper to the TextFormats library, for using it
in the Python programming language.
`C_API.md`
: Describes the API of the wrapper to the library, for using it in the C and
C++ programming languages.
`CLI.md`
: Describes the command line interface of TextFormats: a collection of tools,
for decoding, encoding, validating data, inspecting and testing specifications
and more.
`developer_manual.md`
: Code organization and conventions, used in the implementation of the
TextFormats library. This is addressed to the library software developer,
not to the library user.

### Cheatsheets

Under the directory `cheatsheets` are cheatsheets, im Markdown format,
containing tables, summarizing the specification syntax and test syntax,
and the usage of the Nim, Python and C API as well as the CLI tools.

## Validating a specification

Using `tf_spec info -s <SPECFILE>` the list of datatypes of a (valid)
specification are output. An error will be output if the specification
is invalid.

A further tool to validate the syntax of a YAML or JSON specification, which can
be sometimes useful to find specification errors, is `tf_cerberus.py`,
based on the Python library `cerberus` (which is required in order to use this
tool). The script has some limitations: it is not always guaranteed that a
validated specification is indeed valid (e.g. circular or invalid references
are not found).

## Generating a specification

An interactive script `tf_genspec.py` is provided under `scripts`.  It can be
used to generate a TextFormats specification in YAML file.
The script has some limitations: it is not always guaranteed that the generated
specification is correct (e.g. the user can create circular or invalid
references).

Thus the resulting output file should be tested, e.g. generating examples
from each of the defined datatypes using `cli/tf_spec generate_tests -s
<OUTFILE>`. This command would fail if the specification is invalid.
Furthermore, the results can be inspected to check that the examples reflect
the expectations.

## Running the test suite

To run the unit test suite of the library, use the
``nimble test`` command.
To run the CLI tools tests, first build it using ``nimble build`` or
``nimble install``, then use the ``nimble clitest`` command.
To run the C API tests, use ``nimble ctest``.
To run the Python API tests, first build the package using
``nimble pymake``, then use ``nimble pytest``.

## Known limitations

- Only formats which are regular languages can be defined -- with at most some
  exceptions (JSON elements can be included, since they are parsed by the json
  library).
- Unsigned integers cannot be larger than the largest signed integer [^2]

[^2]: reason: JsonNode objects from the json nim standard library are
used to represent decoded values both for Nim code and for passing the values
through the API to functions written in other languages; however, JsonNode does
not have a representation for unsigned integers)
