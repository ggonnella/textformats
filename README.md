# TextFormats

TextFormats is a library for rapidly defining and using text formats for
structured data, and allows for rapid prototyping of parsers for
such file formats in Nim, Python and C/C++.

Given a format definition, expressed in a simple declarative language (TFSL,
Text Formats Specification Language), the library provides functions for
switching from the text representation of the data ("encoded string") to the
actual data it represents ("decoded data") and vice-versa.

The definition of the formats in TFSL is human readable and reduces the
requirement of complex regular expression. As opposed to lexers or regular
expressions, it does not only validates and splits different parts of a format,
but converts them to data in built-in scalar and compound datatypes, allowing
for fine tuning of the conversion.

## Python

The Python API of TextFormats is documented in the
[Python API manual](https://github.com/ggonnella/textformats/blob/main/manuals/Python_API.md)
and [cheatsheet](https://github.com/ggonnella/textformats/blob/main/cheatsheets/Python_API.md)
and can be installed using:

```
pip install textformats
```

If a binary package compatible with the system is available, it will
be downloaded and installed. Nim installation is not required.

If no binary package is available, the source distribution is downloaded.
In this case, the [Nim compiler version >= 1.6.0 must be installed](https://github.com/ggonnella/textformats/blob/main/manuals/howto_install_nim.md)
and the ``nim`` binary must be in PATH.  Then,
the ``pip install textformats`` command will automatically compile and install
the package.

Example applications based on the Python API are available in the git repository
[here](https://github.com/ggonnella/textformats/tree/main/python/examples)
and [here](https://github.com/ggonnella/textformats/tree/main/python/benchmarks).

## Nim

The Nim API of TextFormats is documented in the
[Nim API manual](https://github.com/ggonnella/textformats/blob/main/manuals/Nim_API.md)
and [cheatsheet](https://github.com/ggonnella/textformats/blob/main/cheatsheets/Nim_API.md).
and is installed using:

```
nimble install textformats
```

Example applications based on the Nim API are available in the git repository
[here](https://github.com/ggonnella/textformats/tree/main/examples)
and [here](https://github.com/ggonnella/textformats/tree/main/benchmarks).

## C/C++

The C API of TextFormats is documented in the
[C API manual](https://github.com/ggonnella/textformats/blob/main/manuals/C_API.md)
and [cheatsheet](https://github.com/ggonnella/textformats/blob/main/cheatsheets/C_API.md)
and is obtained by cloning the
[git repository](https://github.com/ggonnella/textformats.git).
Furthermore [Nim compiler version >= 1.6.0 must be installed](https://github.com/ggonnella/textformats/blob/main/manuals/howto_install_nim.md)

The C API are in the in the ``C`` directory of the git repository.
Example applications based on the C API are available in the git repository
[here](https://github.com/ggonnella/textformats/tree/main/C/examples)
and [here](https://github.com/ggonnella/textformats/tree/main/C/benchmarks).

## Command line tools

The CLI tools developed with TextFormats allows the use of the library
from the command line (e.g. in Bash scripts). For using it, the
[Nim compiler version >= 1.6.0 must be installed](https://github.com/ggonnella/textformats/blob/main/manuals/howto_install_nim.md)
and the textformats Nim package installed (``nimble install textformats``).
The tools are thereby installed and compiled. They are ``tf_spec`` (work with TFSL specifications),
 ``tf_decode`` (convert a format to JSON), ``tf_encode`` (convert JSON to a format)
  and ``tf_validate`` (validate data or its text representations).

The CLI tools are documented in the
[CLI manual](https://github.com/ggonnella/textformats/blob/main/manuals/CLI.md),
[cheatsheet](https://github.com/ggonnella/textformats/blob/main/cheatsheets/CLI.md).
Man pages can be generated using ``nimble climan`` from the source code
directory.

Examples of use of the CLI tools are given in the git repository
[here](https://github.com/ggonnella/textformats/tree/main/cli/examples)
[here](https://github.com/ggonnella/textformats/tree/main/cli/tests).

## Format specifications

The TFSL (TextFormats Specification Language) is usually input by the user
as a YAML file. In alternative, the interactive Python script `tf_genspec.py`
can be used, which allows the generation of a specification from scratch.

Several specifications are made available with the package and are contained
in the git repository in the
[spec directory](https://github.com/ggonnella/textformats/tree/main/spec)

The specification language is documented in a
[manual](https://github.com/ggonnella/textformats/blob/main/manuals/TFSL_syntax.md),
and a
[cheatsheet](https://github.com/ggonnella/textformats/blob/main/cheatsheet/TFSL.md),
describing the syntax,
a [howto](https://github.com/ggonnella/textformats/blob/main/manuals/TFSL_howto.md)
explaining how to define text representations
for different kind of values: strings, numeric, boolean, list, dictionaries, etc.
and a
[tests manual](https://github.com/ggonnella/textformats/blob/main/manuals/TFSL_tests.md),
describing how to implement specification tests.

### Format specifications: an example

In multiple biological sequence analysis formats (e.g. SAM, GFA),
a CIGAR string represents a list of multi-edit operations, each consisting
of a length (positive integer value) and an operation code (one among a short
list of possible codes).

A string representation of a CIGAR is for example
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
# decoding: string representation => data
"10M1D".decode(cigar)
# => [{length: 10, code: "M"}, {length: 1, code: "D"}]

# encoding: data => string representation
[{length: 10, code: "M"}, {length: 1, code: "D"}].encode(cigar)
# => "10M1D"

# validation of string representation
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
sometimes a given symbol or part of a string representation is missing
when representing a default value.

### Understanding specification errors

The tool ``tf_spec`` (see above Command line tools) can be used as
`tf_spec info -s <SPECFILE>` to list of datatypes of a (valid)
specification are output. An error will be output if the specification
is invalid.

A further tool to validate the syntax of a YAML or JSON specification, which can
be sometimes useful to better understand specification errors, is `tf_cerberus.py`,
provided under `scripts` in the
source code git repository.
It is based on the Python library `cerberus` (which is required in order to use this
tool). The script has some limitations: it is not always guaranteed that a
validated specification is indeed valid (e.g. circular or invalid references
are not found).

### Interactive generation

An interactive script `tf_genspec.py` is provided under `scripts` in the
source code git repository.  It can be
used to generate a TextFormats specification in YAML file.
The script has some limitations: it is not always guaranteed that the generated
specification is correct (e.g. the user can create circular or invalid
references).

Thus the resulting output file should be tested, e.g. generating examples
from each of the defined datatypes using `cli/tf_spec generate_tests -s
<OUTFILE>`. This command would fail if the specification is invalid.
Furthermore, the results can be inspected to check that the examples reflect
the expectations.

## Developer notes

The library is implemented using the programming language Nim.
This language was used, since it combines some of the advantages of Python
with those of compiled languages.

During compilation, C code is created and then compiled to binary.
Besides in Nim code itself, the resulting library can be easily employed
in C/C++ and in Python.

Code organization and conventions, used in the implementation of the
TextFormats library, addressed to the library software developer,
are documented in the
[developer manual](https://github.com/ggonnella/textformats/blob/main/manuals/developer_manual.md)

To run the unit test suite of the library, use the
``nimble test`` command from the main project source code directory.
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
