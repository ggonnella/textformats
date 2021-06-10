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

## Running the test suite

To run the unit test suite of the library in your system, use the
``nimble test`` command.

## Using TextFormats library in C

In the subdirectory C there is a ``c_api.nim`` file.

This contains simple wrappers for the API functions of TextFormats, which
allow to pass C strings as arguments, and export the functions to C using the
{.exportc.} Nim pragma. The wrapper is compiled using ``nim c``
with the flags ``--noMain --noLinking --header:c_api.h --nimcache:$NIMCACHE``,
where $NIMCACHE is the location where the compiled files will be stored.

The API is then included into the C file (``#include "c_api.h"``) and linked
using the following compiler flags before the name of the C file to compile:
``-I$NIMCACHE -I$NIMLIB $NIMCACHE/*.o`` where NIMLIB is the location of the NIM
library[^1].

In the C code, the Nim library must be initialized calling the function
NimMain().

Similar to the interface in other languages, using the TextFormats library
requires first to parse the format specification. This is done using the
function ``parse_specification(filename)`` (for YAML specification files)
or ``load_specification(filename)`` (for preprocessed specification files).
The returned (void) pointer is then used to retrieve (void) pointers to
datatype definitions using the function ``get_definition(spec,
datatype_name)``. These are then passed to the encode, decode and validation
functions.

The available encode, decoded, validation functions and their interfaces
are the same as in the Nim and Python API. Encoded data is decoded using
``decode``, ``recognize_and_decode``, or ``to_json``, or validated
using ``is_valid_encoded``. Decoded data is encoded using ``encode``,
``unsafe_encode``, ``from_json`` or ``unsafe_from_json``, or validated
using ``is_valid_decoded``.

Information is passed to the TextFormats library as C strings (encoded data)
or as JsonNode objects (decoded data). A C wrapper to the Nim JsonNode library
is provided under ``C/jsonwrap``. Examples of how to create a JsonNode in the C
code for string and numerical scalar values, NULL, arrays and dictionaries
(with any level of nesting) are given under ``C/jsonwrap/tests/``. To print
the content of a JsonNode, the ``to_string(node)`` function can be used.
The memory for JsonNode instances, whether explicitely created or returned
by a library function, must be marked as free using ``GC_unref_node(node)``.

[^1] If you use choosenim for managing Nim versions, the location of the
library will be in the choosenim directory (default: ~/.choosenim) under
toolchains/nim-$VERSION/lib where $VERSION is the version of Nim you are
using (e.g. 1.4.8).

## Known limitations

Unsigned integers cannot be larger than the largest signed integer [^2]

[^2]: reason: JsonNode objects from the json nim standard library are
used to represent decoded values both for Nim code and for passing the values
through the API to functions written in other languages; however, JsonNode does
not have a representation for unsigned integers)
