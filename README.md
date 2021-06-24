# TextFormats

## Purpose

TextFormats is a library for rapidly defining and using text formats
for structured data.

Given a format definition, the library provides functions for switching
from the textual representation of data ("encoded string") to the actual
data which the text represents ("decoded data") and vice-versa.

The library aims at allowing rapid prototyping of libraries for supporting
file formats in Nim, C and Python, by providing base functionality,
on which further operations can be added. Furthermore, the definition
of the formats aims at being human readable and reducing the requirement
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

The definition of a CIGAR in Textformats would be:
```
cigar:
  list_of:
    composed_of:
    - length: {unsigned_integer: {min: 1}}
    - code: {accepted_values: [M, D, I, P] }
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
cigar_code: {accepted_values: [M, D, I, P]}
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

The subdirectory ``cli`` contains the command line tool ``textformats_cli``.
It consists of a number of subcommands, which are selected using the first
argument. The list of subcommands is output by ``textformats_cli --help``.
The mandatory and optional arguments of each subcommand are output by
``textformats_cli <SUBCOMMAND> --help``.

The tool can be used to encode, decode and validate strings or data files
from the command line, as well as tests and a number of additional
operations on specification files, as illustrated below.

### Preprocess a specification

The specification YAML file can be preprocessed and marshalled to file.
In some cases, a preprocessed specification is faster to load than the parsing
of the YAML specification (since no validation occurs and the regular
expressions are already compiled).

Thus when a specification is used multiple times, it can be convenient to
preprocess it. The current marshalling format is the one used by the Nim
``marshal`` library, which is mostly a JSON format (although its not
guaranteed to be JSON-compliant).

To preprocess a specification, use the following command:
``textformats_cli preprocess -s YAML_SPEC -o PREPROCESSED_SPEC``
where YAML_SPEC is the input specification, in YAML format and
PREPROCESSED_SPEC is the output file.

All other subcommands of ``textformats_cli`` accept both YAML and preprocessed
specifications (passed to them with the ``--specfile`` or ``-s`` option).
In case preprocessed specifications are used, the ``--preprocessed`` or
``-p`` flag must be set.

### Decode strings

To decode an encoded string according to a datatype, and output it as the
JSON representation of the decoded data, the ``decode`` subcommand is used.

The ``decode`` subcommand requires the input string, provided using the option
``--encoded`` or ``-e``. The path to the specification file is provided through
the option ``--specfile`` or ``-s``. If the specification is preprocessed, the
flag ``--preprocessed`` or ``-p`` must be set. The datatype to be used for
decoding is selected using the ``--datatype`` or ``-t``.

### Encode data

To encode data (represented as a JSON string) to an encoded representation
according to a given datatype definition, the ``encode`` subcommand is used.

The ``encode`` subcommand requires the input string (JSON representation of
the data to encode), provided using the option ``--decoded_json`` or ``-d``.
The path to the specification file is provided through the option ``--specfile``
or ``-s``. If the specification is preprocessed, the
flag ``--preprocessed`` or ``-p`` must be set. The datatype to be used for
encoding is selected using the ``--datatype`` or ``-t``.

### Decode files

TODO: describe ``decode_lines``, ``decode_embedded``, ``decode_units``,
``linetypes``.

### Analysing a specification file

#### List of datatype definitions

For a list of all definitions in a specification file (YAML or preprocessed),
use the subcommand ``list``. The path to the specification file is provided
through the option ``--specfile`` or ``-s``. If the specification is
preprocessed, the flag ``--preprocessed`` or ``-p`` must be set.
The list includes all datatypes defined by included files. It does not contain
the predefined basic datatypes.

#### Show a datatype definition

Using the subcommand ``show``, a string representation of the DatatypeDefinition
corresponding to a datatype definition can be output. This can be useful for
debug, as well as to understand more specifically how a datatype definition
is handled (e.g. how does the generated regular expression look like).

The path to the specification file is provided through the option ``--specfile``
or ``-s``. If the specification is preprocessed, the
flag ``--preprocessed`` or ``-p`` must be set. The datatype to be shown
is selected using the ``--datatype`` or ``-t``.

### Validate data

TODO: describe ``validate`` subcommand and its subsubcommands.

### Autogenerate test data for a specification

TODO: describe the ``generate_tests`` subcommand

### Run tests

TODO: describe ``test`` subcommand and its subsubcommands.

## Testing a specification

### Testdata YAML syntax

The test data for a specification, either manually or automatically generated,
is written in YAML format. It can be written in the same file as the
specification itself, or in a separate file.

As for the specification, the YAML document (which must be the first YAML
document in the file) must contain a mapping. Test data are written
under the key 'testdata' under the mapping root.

The 'testdata' key contains a mapping, where the names of the datatypes to be
tested are the keys. Each of the datatype keys contain a mapping, where
examples of both valid and invalid textual representations and decoded data can
be given, respectively under the keys 'valid' and 'invalid':
```
testdata:
  datatype1:
    valid: ...
    invalid: ...
```

#### Examples of valid data

Valid data is given as a mapping under 'valid', where the keys are the encoded
textual form and the values are the decoded data:
```
valid: {"encoded1": "decoded1", ...}
```
The tests will both check that the encoded data is decoded as given, and
the opposite, i.e. that the decoded data is encoded as given.

#### Examples of invalid data

Invalid data is given under the key 'invalid'. Under it, textual
representations and decoded data are given as lists under, respectively,
the subkeys 'encoded' and 'decoded':
```
invalid:
  encoded: ["3", ...]
  decoded: [3, ...]
```

#### Testing invariant string datatypes

As a particular case, if a datatype consists of strings, which are not
further processed (i.e. encoded and decoded form are the same), valid and/or
invalid strings can be conveniently just be imput as an array of strings:
```
valid: ["string1", "string2", ...]
invalid: ["string1", "string2", ...]
```

#### Testing non-canonical textual representations

In some cases, however, only the decoding shall be tested, because the data
has a "canonical" textual representation (obtain by encoding), but further
representations are valid as well, and can be decoded.

Another mapping key ('oneway') is used for handling tests of these non-canonical
representations. Like under 'valid', the data is given as a mapping with
encoded string representations as keys and the decoded data as values:
```
oneway: {"+2": 2, ...}
```
For data under 'oneway' only the decoding is tested, since this is not
the result which one would obtain from encoding the same decoded data.

##### Example of testing non-canonical representations

For example a string representing a positive integer, can contain "2" which
will be decoded to the integer value 2. Reversing the operation, this value
would be encoded as the same string, i.e. containing "2". Also a
string with "+2" will be decoded to the same integer value 2. However, when
reversing the operation, this time the result of the encoding will be different
than the original string ("2" instead of "+2").

Thus, a both-ways test would fail:
```
valid: {"2": 2, "+2": 2} # this would fail
```
When moving the canonical representation under oneway will the test will
succeed:
```
valid: {"2": 2}
oneway: {"+2": 2}
```

## Known limitations

Unsigned integers cannot be larger than the largest signed integer [^2]

[^2]: reason: JsonNode objects from the json nim standard library are
used to represent decoded values both for Nim code and for passing the values
through the API to functions written in other languages; however, JsonNode does
not have a representation for unsigned integers)
