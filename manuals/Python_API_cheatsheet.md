# Installation

|                             |                                   |
| --------------------------  | --------------------------------- |
Requirements                  | `pip install nimporter`
Compile Python wrapper        | `cd python && make`
Use the module                | `import textformats`

# Specifications

|                             |                                   |
| --------------------------  | --------------------------------- |
Parse/load specification    | `spec = Specification(filename)`
Construct specification programmatically | `Specification({"datatypes": {...}})`
List datatype names         | `spec.datatype_names(spec)`
Filename of spec object     | `spec.filename`
                            |
Preprocess specification    | `Specification.preprocess(infn, outfn)`
Check if preprocessed       | `spec.is_preprocessed`
                            |
Run tests in file           | `spec.test(testfn)`
Run tests constructed programmatically | `spec.test({"testdata": {...}})`


# Datatype definitions

|                           |                                   |
| ------------------------- | --------------------------------- |
Get a datatype definition   | `ddef = specification["datatype_name"]`
Get verbose description     | `str(ddef)`
Get code for definition     | `repr(ddef)`


# Decoding, encoding and validating strings

|                             |                                   |
| --------------------------  | --------------------------------- |
Decode string to Python data  | `node = ddef.decode(string)`
Decode string to JSON string  | `node = ddef.decode(string, true)`
Encode from Python data       | `encoded = ddef.encode(data)`
Encode from JSON string       | `encoded = ddef.encode(data, true)`
Validate text format          | `boolvar = ddef.is_valid_decoded(string)`
Validate data for text format | `boolvar = ddef.is_valid_encoded(data)`
Validate JSON str for text format | `boolvar = ddef.is_valid_encoded(data, true)`

# Decoding a file

|                                 |                                   |
| ------------------------------- | --------------------------------- |
Decode file (wo embedded spec)    | `for elm in ddef.decoded_file(fname)`
Decode file with embedded spec    | `for elm in ddef.decoded_file(fname, True)`
Yielding single elements of ddef  | `for elm in ddef.decoded_file(fname, bool, True)`
Yielding JSON strings             | `for elm in ddef.decoded_file(fname, bool, bool, True)`
                                  |
Using a processing function       | `decode_file(fname, ddef, has_embedded_spec_bool,`
                                  | `            decoded_processor, decoded_proc_data,`
                                  | `            decoded_proc_level, to_json)`

Signature of decoded processor fn    | `decoded_processor(decoded_element, proc_data)`
Decoded processor levels             | 0: whole file/section;
(scope `file`/`section`)             | 1: element of compound definition;
                                     | 2: single lines
Set scope of definition              | `ddef.scope = scope`
where scope is (string):             | `line`, `unit`, `section` or `file`
Set unitsize (scope `unit`)          | `ddef.unitsize = int_nlines`
Report branch of `one_of` definition | `ddef.wrapped = True`
(turn off branch wrapping)           | `ddef.wrapped = False`
