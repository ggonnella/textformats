# TextFormats

## Introduction

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

## Notes about the implementation

The library is implemented using the programming language Nim.
This language was used, since it combines some of the advantages of Python
with those of compiled languages.

During compilation, C code is created and then compiled to binary.
Besides in Nim code itself, the resulting library can be easily employed
in C/C++ and in Python.

## Running the test suite

To run the unit test suite of the library in your system, use the
``nimble test`` command.

# Interface

## Nim API

The public API of the library is defined in the file ``src/textformats.nim``.
The following assumes that a valid specification has been defined (manually
or through the interactive script) and stored as a YAML file.

### Types

The types used when working with the API are ``Specification`` and
``DatatypeDefinition``. A ``Specification`` object is a table
whose keys are datatype names and values datatype definitions.
A ``DatatypeDefinition`` contains the definition, including references
to other nested definitions, the regular expression needed for
parsing, rules for validation and data conversion/transformation.
Exceptions are defined in ``src/textformats/types/textformats_error``
and are descandants of ``TextFormatsError``.

### Working with the specification

The function ``parse_specification(filename)`` is used to obtain a Specification
object from a YAML file. An exception is thrown if the file cannot be found or
opened, or if the format or YAML content are invalid.

Parsed specifications can be marshalled to file using the
``Specification.save_specification(filename)`` method (note that the method
is destructive, i.e.\ if used, the specification is invalid and must be
reloaded). Unmarshalling of file containing a parsed specification
is done using the ``load_specification(filename)`` function, which returns
a Specification object.

In order to use the content of the specification, the required datatypes
are obtained from it, using the function
``Specification.get_definition(datatype_name)``, which returns a
``DatatypeDefinition`` object.

### Decoding the string representation of data

For decoding a string containing the string representation of the data,
as defined in one of the datatypes of the specification, the method
``string.decode(datatype_definition)`` is used. The function returns
a JsonNode object. JsonNode is a variant type (described in the documentation of
the Nim json library), capable to represent scalar values (null, strings,
booleans, floats, signed integers), sequences/arrays/lists/tuples, and
tables/maps/dictionaries. Container types can be nested.

#### Validating the string representation without decoding

If it is only necessary to know if the data in the string
representation are valid or not, according to a given
datatype definition, it is possible to use the method
``string.is_valid(datatype_definition)`` instead of ``decode``.
The advantage is that in many cases not all the operations
necessary for decoding are done, thus the method can be
more efficient than using ``decode``.

#### Multiple alternative datatypes

If a string contains one of multiple types of data, a ``one_of`` datatype
definition can be used as datatype definition. The ``decode`` function then
correctly decodes the string but does not tell which of the branches
of the ``one_of`` definition have been used. If this is required,
the ``string.recognize_and_decode(one_of_datatype_definition)`` can be
used, which returns a named 2-tuple, where ``name`` is the
name of the used branch (string) and ``decoded`` is the JsonNode object
containing the decoded data.

#### Decoding from file

In many cases the textual representation of the data is contained in a file.
Using the ``filename.decode_lines(datatype_definition)`` iterator, each line of
the file is passed to ``decode`` and the resulting JsonNode objects are yielded.

#### Files with different line types

If different kind of lines exist and a ``one_of`` definition is used,
the branch of ``one_of`` used for the decoding can be yielded as well,
by using the ``filename.recognize_and_decode_lines(one_of_datatype_definition)``
iterator. This is the file line iterator equivalent of ``recognize_and_decode``
(described above).

#### Files with different line types in a specific order

If different line types exists in a specific order in a file,
a ``composed_of`` datatype definition can be used to describe
the units of the file structure. This definition shall have
newline as a separator (``sep: "\n"``) and no prefix and suffix.

The definition can then be passed to the
``filename.decode_units(composed_of_datatype_definition)`` method, which
yield JsonNode objects as the ``decode`` method.
The advantage of using this method is that it automatically
recognize the borders of the units. as described by the
``composed_of`` definition.

#### Embedded specifications

Data files can contain an embedded YAML specification which desribes the
data format. For this, the file shall start with the YAML specification
(without any initial document separator ``---```). The data shall then
follow the first document separator in the file (line containing only exactly
``---``).

Data files with embedded specifications are decoded as follows. First,
the specification is parsed, as usual, using ``parse_specification(filename)``
and a datatype definition is obtained from it, as described above.
The same filename is then passed to the iterator
``filename.decode_embedded(datatype_definition)``, which has the same
interface as ``decode_lines``, but ignores the specification (i.e. everything
up to the first ``---`` line found in the file).

TODO: is the name of ``decode_file_linewise`` appropriate?
Because it looks like it actually decodes units (using
decode_multiline_lines).

TODO: The following are exported by decode but currently not exported to the API:
``decode_line_groups``
``decode_multiline_lines``
``decode_multilines``

### Encoding data to their string representation

In order to encode data to their string representation, according to
a datatype definition, it is first necessary to create
a JsonNode object containing the data (this is usually
very easily done using the ``%`` macro, see the ``json``
library documentation).
The string representation is then returned by the
``json_node.encode(datatype_definition)`` method.

#### Validating data without encoding

If it is only required to know if the data is valid according to a datatype
definition, but the string representation must not be computed, the method
``json_node.is_valid(datatype_definition)`` can be used instead of
``encode``. The advantage is that, since often the string representation is not
computed (it depends on the datatype), the method can be more efficient
than ``encode``.

#### Encoding data which is guaranteed to be valid

The ``encode`` method checks that the data is valid according to the datatype
definition while computing the string representation (and raises an exception
if not). Sometimes the data is guaranteed to be valid and some of the checks
can be skipped, so that the encoding is more efficient: in this case
the ``json_node.unsafe_encode(datatype_definition)`` method can be used
instead. The method has the same interface as ``encode``, but may return
invalid string representations if invalid data is passed to it, instead of
raising an exception.

## Python API

The subdirectory ``python`` contains the Python API, as a pip package.
Two interfaces are provided for accessing the data in Python.

### Python bindings of the public Nim API

The first interface is contained in the ``textformats.py_binding`` module.
It consists in direct bindings of the
Nim public API functions described above.

The main differences compared to the Nim functions are the following.
First, Python objects (None, True, False, strings, integers, floats,
lists, tuples and dictionaries, with any level of nesting) are passed to
the encoding functions (instead of JsonNode).
Second, to avoid a name clash, the ``is_valid`` methods are splitted into
distinctly named ``string.is_valid_encoded(datatype_definition)`` and
``data.is_valid_decoded(datatype_definition)``.

### Using the JSON representation of the data

Since passing objects between Nim and Python can be expensive in terms
of resources, further methods are defined, which pass the JSON
representation of the data instead.
The ``string.to_json(datatype_definition)`` is the
equivalent of ``decode``, but returns a string (Json representation of the
decoded data) instead of a Python object. The
``json_string.from_json(datatype_definition)`` is the
equivalent of ``encode`` and returns a string representation
according to the given datatype definition of the ``json_string``
data (represented as JSON). Similarly ``unsafe_from_json`` is
the equivalent of ``unsafe_encode`` (described above), with
the same interface as ``from_json``.

### Python object oriented API

A second API (object oriented) is also provided, which feels more pythonic.
Two classes are defined: Datatype and Specification.

Specification objects are created passing the filename as
argument to the constructor. Using
``spec[datatype_name]`` method,
a Datatype object is extracted from the specification.

The decoding, encoding and validation functions are then
expressed as methods of the datatype object, i.e.
``datatype.decode(encoded_string)``,
``datatype.recognize_and_decode(encoded_string)``,
``datatype.to_json(encoded_string)``,
``datatype.is_valid_encoded(encoded_string)``
for handling the text representation, and
``datatype.encode(decoded_data)``,
``datatype.unsafe_encode(decoded_data)``,
``datatype.from_json(decoded_data)`` for handling
the data in decoded form.

## C API

The subdirectory ``C`` contains a ``c_api.nim`` file.  which contains simple
wrappers for the API functions of TextFormats, which allow to pass C strings as
arguments, and export the functions to C using the {.exportc.} Nim pragma. The
wrapper is compiled using ``nim c`` with the flags ``--noMain --noLinking
--header:c_api.h --nimcache:$NIMCACHE``, where $NIMCACHE is the location where
the compiled files will be stored.

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

## Command line

The subdirectory ``cli`` contains the command line interface.

## Known limitations

Unsigned integers cannot be larger than the largest signed integer [^2]

[^2]: reason: JsonNode objects from the json nim standard library are
used to represent decoded values both for Nim code and for passing the values
through the API to functions written in other languages; however, JsonNode does
not have a representation for unsigned integers)
