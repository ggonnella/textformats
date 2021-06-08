# TextFormats

TextFormats is a library for defining text formats for structured data.

Once a text format is defined, the library automatically provides a
parser, which allows to encode, decode and validate data in the format.
The library can be conveniently accessed from multiple programming languages:
examples are given in Python, Nim and C. A command line tool is also provided to
access the library functions from the command line.

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

## Known limitations

Unsigned integers cannot be larger than the largest signed integer [^1]

[^1]: reason: JsonNode objects from the json nim standard library are
used to represent decoded values both for Nim code and for passing the values
through the API to functions written in other languages; however, JsonNode does
not have a representation for unsigned integers)
