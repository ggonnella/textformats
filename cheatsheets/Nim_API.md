
# Datatypes

|                             |                                   |
| --------------------------  | --------------------------------- |
Text format specification     | `Specification`
Definition of a datatype      | `DatatypeDefinition`
Errors                        | `TextFormatsError` and descendants

# Specifications

|                             |                                   |
| --------------------------  | --------------------------------- |
Parse/load specification    | `specification_from_file(filename)`
Parse specification string  | `parse_specification(string)`
List datatype names         | `datatype_names(spec): seq[string]`
                            |
Compile specification       | `compile_specification(infn, outfn)`
Check if compiled           | `is_compiled(filename)`
Run tests in file           | `run_specification_testfile(spec, testfn)`
Run tests in string         | `run_specification_tests(spec, string)`

# Datatype definitions

|                           |                                   |
| ------------------------- | --------------------------------- |
Get a datatype definition   | `ddef = get_definition(spec, datatype_name)`
Get verbose description     | `$ddef`
Get code for definition     | `repr(ddef)`

# Decoding, encoding and validating strings

|                             |                                   |
| --------------------------  | --------------------------------- |
Decode string to JsonNode     | `node = decode(string, ddef)`
Encode from JsonNode          | `encoded = encode(node, ddef)`
Validate text format          | `boolvar = is_valid(string, ddef)`
Validate data for repr in text format | `boolvar = is_valid(json_node, ddef)`

# Decoding a file

|                                 |                                   |
| ------------------------------- | --------------------------------- |
Decode file (wo embedded spec)    | `for elm in decoded_file(fname, ddef, false, false)`
Decode file with embedded spec    | `for elm in decoded_file(fname, ddef, true, false)`
Yielding single elements of ddef  | `for elm in decoded_file(fname, ddef, bool, true)`
Using a processing function       | `decode_file(fname, ddef, has_embedded_spec_bool,`
                                  | `            decoded_processor, decoded_proc_data,`
                                  | `            decoded_proc_level)`

Signature of decoded processor fn    | `void decoded_processor(JsonNode *n, void *data)`
Decoded processor levels             | DplWhole: whole file/section;
(scope `file`/`section`)             | DplElement: element of compound definition;
                                     | DplLine: single lines
Set scope of definition              | `set_scope(ddef, scope)`
where scope is (string):             | `line`, `unit`, `section` or `file`
Set unitsize (scope `unit`)          | `set_unitsize(ddef, int_nlines)`
Report branch of `one_of` definition | `set_wrapped(ddef)`
(turn off branch wrapping)           | `unset_wrapped(ddef)`

