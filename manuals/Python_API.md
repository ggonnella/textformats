# Python API

The subdirectory `python` contains the Python API, as a pip package.

## Building from source code

In order to build the Python API package from the source code,
besides the `nim` and `C` compiler (e.g. `gcc` or `clang`), the Python
library `nimporter` is required, which can be installed using `pip`.

The provided `Makefile` can then be used. Its default goal is to compile and
install the package. If necessary, provide the path to the python interpreter
in the variable PYTHON (default: `python3`).

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

```Python
import textformats as tf

# use a specification from file:
s = Specification("myspec.yaml")

# alternative:
# define the specification using a dict:
mydatatype_def = {"list_of": "unsigned_integer", "splitted_by": "--"}
s = Specification({"datatypes": {"mydatatype": mydatatype_def}})

# get the datatype definition
d = s["mydatatype"]

# convert between data (Python objects) and their encoded representation
decoded = d.decode("1--2--3")
encoded = d.encode([1, 2, 3])

# alternative:
# convert to/from JSON strings representing the data and encoded representation
decoded = d.decode("1--2--3", True)
encoded = d.encode("[1,2,3]", True)
```

More examples are provided under `python/examples`.

## Specifications

The class `Specification` represents a TextFormats specification.
To parse a YAML, JSON specification or load a preprocessed specification
use the class constructor `Specification(filename)`.
Alternatively a dict can be passed to the constructor, which contains
the datatypes definitions: `Specification({"datatypes": {...}})`.

The following properties are defined in the Specification instances:
`datatype_names` is the list of the names of the datatypes
defined in the specification; `filename` is the filename from which
the specification instance was constructed; `is_preprocessed` is a boolean,
which is `True`, if the specification is preprocessed.
The suggested file extension for preprocessed specifications
is `tfs` (*T*ext*F*ormats *S*pecification).

To preprocess a specification, use the class method
`Specification.preprocess(inputfile, outputfile)`.

To run the test suite for a specification use the method
`specification.test(testfile)`. If the testdata is contained
in a YAML/JSON specification, `specification.test()` will run the test.
Alternatively it is possible to pass testdata constructed
programmatically as a dict: `specification.test({"testdata": {...}})`.

## Datatype definitions

To obtain a datatype definition from a specification use the item getter
operator `specification["datatype_name"]`. The obtained datatype
definition instance can be used for decoding, encoding and validating data.

The string representation `str(datatype_definition)` is the verbose
description of the specification.

## Decoding the string representation of data

The method `datatype_definition.decode(string, to_json=False)` is used to
decode a string which follows the given datatype definition.
By default the return value is the data as an instance
of `NoneType`, `bool`, `int`, `float`, `str`, `list` or `dict`.
If the optional boolean flag `to_json` is set a JSON string representation
of the decoded data is returned instead.

### Encoding data to their string representation

The method `datatype_definition.encode(item, from_json=False)` is used to
encode data using the given datatype definition.
By default the data to be encoded is passed as an instance of
`NoneType`, `bool`, `int`, `float`, `str`, `list` or `dict`.
Alternatively the JSON string representation of the data can be passed;
in this case the `from_json` optional boolean flag must be set.

## Validating data or their string representation

If is only necessary to know if encoded or decoded data follow a
datatype definition, and no access to the result of decoding or encoding is
necessary, the validation functions can be used. Depending on the datatype
definition, they can be faster than full decoding or encoding.

The method `datatype_definition.is_valid_encoded(string)`
can be used to validate an encoded string.

The method `datatype_definition.is_valid_decoded(data, json=False)` is used
to determine if the data could be validly represented using the definition.
By default, instead of directly providing the data
to the method, its JSON representation can be passed; in this case
the optional boolean flag `json` must be set.

## Decoding a file

To decode a file, the following iterator is used:
```Python
datatype_definition.decoded_file(filename,
                                 embedded=False, splitted=False, wrapped=False,
                                 to_json=False)
```

Thereby the file is decoded into one or multiple values, which are yielded
by the iterator. By default, the data is yielded as Python instances
of `NoneType`, `bool`, `int`, `float`, `str`, `list` or `dict`.
If the optional boolean flag `to_json` is set, the JSON representation
of the data is yielded instead.

### Embedded specitications

The optional boolean parameter `embedded` of `decoded_file` must be set
if the data and the specification are contained in the same file. A data
file may contain an embedded YAML specification, preceding the data and
separated from it by a YAML document separator line (`---`).

### Splitted processing

Definitions at `file` or `section` scope are compound datatypes
(`composed_of`, `list_of` or `named_values`), which consist of
multiple elements (each in one or multiple lines).

If the optional boolean parameter `splitted` of `decoded_file` is set to
`True`, the values yielded by the iterator are not the entire data in the
file section or whole file, but instead the single elements of the compound
datatype.

This is more efficient in the case of
large files, since it is not necessary to represent in memory and process
the entire file or file section at once.

### Scope of the definition

In order to use a definition for decoding a file, a scope must be provided.
This determines which part of the file shall be decoded applying the definition.
The scope can be provided directly in the datatype definition and must be
"line", "unit" (constant number of lines), "section" (part of the file, as long
as possible, following a definition; greedy) or "file".

The scope of a definition can also be set using the property
`datatype_definition.scope=scopestr`, where `scopestr` is a
string containing one of the above values.

If the scope is set to "unit", the number of lines of a unit must be set,
either in the datatype definition, or setting the property
`datatype_definition.unitsize=n_lines` where `n_lines` is a integer
larger than 1.

### Reporting the branch of "one of" used by decoding

When a `one_of` definition is used for decoding, it is possible to set the
decoded value to contain information about which branch was used for the
decoding. This can be set either setting the key `wrapped` in the
datatype definition, or by setting the optional boolean flag
`wrapped` of the `decoded_file` iterator.

