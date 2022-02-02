# TextFormats Python API

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
from textformats import Specification

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
To parse a YAML, JSON specification or load a compiled specification
use the class constructor `Specification(filename)`.
Alternatively a dict can be passed to the constructor, which contains
the datatypes definitions: `Specification({"datatypes": {...}})`.

The following properties are defined in the Specification instances:
`datatype_names` is the list of the names of the datatypes
defined in the specification; `filename` is the filename from which
the specification instance was constructed; `is_compiled` is a boolean,
which is `True`, if the specification is compiled.
The suggested file extension for compiled specifications
is `tfs` (*T*ext*F*ormats *S*pecification).

To compile a specification, use the class method
`Specification.compile(inputfile, outputfile)`.

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
datatype_definition.decoded_file(filename, skip_embedded_spec=False,
                                 yield_elements=False, to_json=False)
```

Thereby the file is decoded into one or multiple values, which are yielded
by the iterator. By default, the data is yielded as Python instances
of `NoneType`, `bool`, `int`, `float`, `str`, `list` or `dict`.
If the optional boolean flag `to_json` is set, the JSON representation
of the data is yielded instead.

In alternative, the following function can be used:
```Nim
datatype_definition.decode_file(filename, skip_embedded_spec,
            decoded_processor, decoded_processor_data,
            decoded_processor_level, to_json=False)
```

The function version, in comparison with the iterator, allows in some cases for
working with smaller pieces of the decoded value at once (see below under
"Level of decoded processing/yielding").

### Embedded specifications

The optional boolean parameter `skip_embedded_spec` of `decoded_file` must be set
if the data and the specification are contained in the same file. A data
file may contain an embedded YAML specification, preceding the data and
separated from it by a YAML document separator line (`---`). In this case
the file decoding function must know that it shall skip the specification
portion of the file while decoding (thus the parameter must be set).

### Level of decoded processing/yielding

Definitions at `file` or `section` scope are compound datatypes (`composed_of`,
`list_of` or `labeled_list`), which consist of multiple elements (each in one
or multiple lines).

The default is to work with the entire file or section at once (`whole` level).
However, in some cases, when a file is large, it is more appropriate to keep
only single elements of the data into memory at once. In particular, these can
be the single elements of the compound datatype (`element` level) or, in cases
these are themselves compound values consisting of multiple lines, down to the
decoded value of single lines (`line` level). Note that working at line level
is not equivalent to having a definition with `line` scope, since the
definition of the structure of the file or file section is still used here for
the decoding and validation.

Unfortunately, because of technical limitations (recursive iterators are not
allowed), the `decoded_file` iterator can only work at `whole` or `element`
level. The default is the `whole` level, while the `element` level is selected
by setting the boolean parameter `yield_elements`.

In contrast, all three levels can be selected, if the proc `decode_file` is
used, setting the parameter `decoded_processor_level` to one of the values
of the `DECODED_PROCESSOR_LEVEL` enum of the `textformats` module:
`DECODED_PROCESOR_LEVEL.WHOLE` (default), `DECODED_PROCESOR_LEVEL.ELEMENT` or
`DECODED_PROCESOR_LEVEL.LINE`.
Further parameters are the processing function
(`decoded_processor`), which is applied to each decoded value (at the selected
level), and `decoded_processor_data`, which can be any value passed to the
processing function, in order to provide to it access to any further necessary
data. The signature of the processing function must be
`process_decoded(node, data)`, where `node` is the decoded value as python
value (if `to_json` is False, default), or as JSON string (if `to_json` is True)
and data is the data passed to `decode_file` as `decoded_processor_data`.
For scope `line` and `unit` the `decoded_processor_level` parameter is ignored.

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
decoding. This is obtained by setting the key `wrapped` in the
datatype definition, or using the `wrapped` property setter of the definition
object.

