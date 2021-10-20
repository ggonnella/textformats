# Nim API

The public API of the library is defined in the file `src/textformats.nim`.

## Quick tutorial by examples

Assuming the specification file `myspec.yaml` contains:
```YAML
datatypes:
  mydatatype:
    list_of: unsigned_integer
    splitted_by: "--"
```

The following code example shows how to load the datatype from the specification
and use it for decoding and encoding data:

```Nim
import textformats

# get the specification and datatype definition from file
let
  s = specification_from_file("myspec.yaml")
  d = s.get_definition("mydatatype")

# convert between data and their text representation, using the definition
let
  decoded = "1--2--3".decode(d)
  encoded = %[1, 2, 3].encode(d)
```

## Types

The types used when working with the API are `Specification` and
`DatatypeDefinition`. A `Specification` object is a table
whose keys are datatype names and values datatype definitions.

A `DatatypeDefinition` contains the definition, including references
to other nested definitions, the regular expression needed for
parsing, rules for validation and data conversion/transformation.

Exceptions are defined in `src/textformats/types/textformats_error.nim`
and are descandants of `TextFormatsError`.

## Working with the specification

The proc `specification_from_file(filename: string): Specification`
is used to obtain a specification from a YAML, JSON or compiled
specification file.

The proc `parse_specification(specdata: string): Specification`
can be used to parse a specification string in YAML or JSON format;
combined with the `%` macro and `$` proc of the `json` library,
it can be used for creating a specification programmatically, e.g.:
```Nim
import tables, json, textformats
let
   mydatatypedef = %{"list_of": "unsigned_integer",
                     "splitted_by": "--"}.to_table
   specdata = %{"datatypes": {"mydatatype": mydatatypedef}}.to_table
   s = parse_specification($specdata)
   d = s.get_definition("mydatatype")
```

The proc `datatype_names(spec: Specification): seq[string]` returns the list
of names of datatypes defined in the specification `spec`.

### Compilation

Specifications can be compiled using the proc
`compile_specification(yamlfilename: string, outputfilename: string)`.
Compiled specifications are marshalled specification objects, after parsing
from the YAML/JSON file, validating, solving references, constructing and
compiling the regular expressions. Compiled files are automatically recognized
by the `specification_from_file` proc.  A limitation of compiled specification
is that they cannot contain test data or be embedded in data files.  The
suggested file extension for compiled specifications is `tfs`
(*T*ext*F*ormats *S*pecification).

### Running tests

It is possible to run a test suite for a specification using the
proc `run_specification_testfile(s: Specification, testfile: string)`.
Alternatively it is possible to provide the test data as a YAML or JSON
string, using the proc
`run_specification_tests(s: Specification, testdata: string)`.

In case the test is unsuccessful, an exception is raised.

## Datatype definitions

To obtain a datatype definition from a specification, use the proc
`get_definition(s: Specification, datatype_name: string): DatatypeDefinition`.

The string representation of the definition (`$(d: DatatypeDefinition)`)
is a verbose text describing the definition in detail.

## Decoding the string representation of data

For decoding a string containing the string representation of the data,
as defined in one of the datatypes of the specification, the proc
`decode(s: string, d: DatatypeDefinition): JsonNode` is used.

JsonNode is a variant type (described in the documentation of
the Nim `json` library), capable to represent scalar values (null, strings,
booleans, floats, signed integers), sequences/arrays/lists/tuples, and
tables/maps/dictionaries. Container types can be nested.

## Encoding data to their string representation

In order to encode data to their string representation, according to
a datatype definition, it is first necessary to create
a JsonNode object containing the data.

This is easily done using the `%` macro For example: `%(@[1,2,3])` constructs
a JsonNode containing the sequence @[1,2,3]. This is usually the only
necessary step. In some cases, such as compound datatypes with
heterologous elements, more functions of the `json` library could be
needed (see its documentation).

The string representation is obtained by calling the proc
`encode(n: JsonNode, d: DatatypeDefinition): string`.

## Validating data or their string representation

If is only necessary to know if encoded or decoded data follow a
datatype definition, and no access to the result of decoding or encoding is
necessary, the validation functions can be used. Depending on the datatype
definition, they can be faster than full decoding or encoding.

The overloaded proc `is_valid()` is used for validation.
 In particular the proc
`is_valid(s: string, d: DatatypeDefinition): bool`
can be used to validate an encoded string.
The proc `is_valid(n: JsonNode, d: DatatypeDefinition): bool` is used
to determine if data could be validly represented using the definition.

## Decoding a file

To decode a file, the following iterator is used:
```Nim
decoded_file(filename: string, dd: DatatypeDefinition,
             skip_embedded_spec = false, yield_elements = false): JsonNode
```

Thereby the file is decoded into one or multiple values, which are yielded
by the iterator as JsonNode instances.

In alternative, the following proc can be used:
```Nim
decode_file(filename: string, dd: DatatypeDefinition,
            skip_embedded_spec = false,
            decoded_processor: proc (node: JsonNode, data: pointer),
            decoded_processor_data: pointer,
            decoded_processor_level: DecodedProcessorLevel)
```

The proc version, in comparison with the iterator, allows in some cases for
working with smaller pieces of the decoded value at once (see below under
"Level of decoded processing/yielding").

### Embedded specifications

The optional boolean parameter `skip_embedded_spec` of `decoded_file` must be
set if the data and the specification are contained in the same file. A data
file may contain an embedded YAML specification, preceding the data and
separated from it by a YAML document separator line (`---`). In this case
the file decoding function must know that it shall skip the specification
portion of the file while decoding (thus the parameter must be set).

### Scope of the definition

In order to use a definition for decoding a file, a scope must be provided.
This determines which part of the file shall be decoded applying the definition.
The scope can be provided directly in the datatype definition and must be
"line", "unit" (constant number of lines), "section" (part of the file, as long
as possible, following a definition; greedy) or "file".

The scope of a definition can also be set using the proc
`set_scope(dd: DatatypeDefinition, scope: string)`, where `scope` is a
string containing one of the above values.

If the scope is set to "unit", the number of lines of a unit must be set,
either in the datatype definition, or using the proc
`set_unitsize(dd: DatatypeDefinition, n_lines: int)` where `n_lines`
is larger than 1.

### Level of decoded processing/yielding

Definitions at `file` or `section` scope are compound datatypes (`composed_of`,
`list_of` or `labeled_list`), which consist of multiple elements (each in one
or multiple lines).

The default is to work with the entire file or section at once (`DplWhole` level).
However, in some cases, when a file is large, it is more appropriate to keep
only single elements of the data into memory at once. In particular, these can
be the single elements of the compound datatype (`DplElement` level) or, in cases
these are themselves compound values consisting of multiple lines, down to the
decoded value of single lines (`DplLine` level). Note that working at line level
is not equivalent to having a definition with `line` scope, since the
definition of the structure of the file or file section is still used here for
the decoding and validation.

Unfortunately, because of technical limitations (recursive iterators are not
allowed), the `decoded_file` iterator can only work at `whole` or `element`
level. The default is the `whole` level, while the `element` level is selected
by setting the boolean parameter `yield_elements`.

In contrast, all three levels can be selected, if the proc `decode_file` is
used, setting the parameter `decoded_processor_level` to `DplWhole` (default),
`DplElement` or `DplLine`. Further parameters are the processing function
(`decoded_processor`), which is applied to each decoded value (at the selected
level), and a pointer `decoded_processing_data`, which is passed to the
processing function, in order to provide to it access to any further necessary
data.
For scope `line` and `unit` the `decoded_processor_level` parameter is ignored.

### Reporting the branch of "one of" used by decoding

When a `one_of` definition is used for decoding, it is possible to set the
decoded value to contain information about which branch was used for the
decoding. This can be set either setting the key `wrapped` in the
datatype definition, or by setting it in the DatatypeDefinition object
using the `set_wrapped(datatype_definition)` proc.

