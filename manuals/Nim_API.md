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

#### Decoding from file

In many cases the textual representation of the data is contained in a file.
Using the ``filename.decoded_lines(datatype_definition)`` iterator, each line of
the file is passed to ``decode`` and the resulting JsonNode objects are yielded.

#### Multiple alternative datatypes

If a string contains one of multiple types of data, a ``one_of`` datatype
definition can be used as datatype definition. The ``decode`` function then
correctly decodes the string but does not tell which of the branches of the
``one_of`` definition have been used. If this is required, the ``wrapped`` flag
can be set, then the decoded value is a mapping, where ``type`` is the name of
the used branch (string) and ``value`` is the decoded data itself.

#### Files with different line types

If different kind of lines exist and a ``one_of`` definition is used,
the branch of ``one_of`` used for the decoding can be recognized
using the flag ``wrapped``, which adds information about the branch
used for decoding to the output.

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

Data files can contain an embedded YAML specification which desribes the data
format. The file is then supposed to contain first a YAML document, with
the specification, then, after a line containing the document separator
(``---``), the data to be decoded.

Data files with embedded specifications are decoded as follows. First,
the specification is parsed, as usual, using ``parse_specification(filename)``
and a datatype definition is obtained from it, as described above.
The same filename is then passed to the iterator
``decoded_lines`` by setting the ``embedded`` flag.

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

