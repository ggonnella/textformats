# Error handling

|                                       |                                   |
| ------------------------------------- | --------------------------------- |
Quit program on any error               | `tf_quit_on_err = true`
Quit if previous function call failed   | `tf_checkerr()`
Check if previous function call failed  | `if (tf_haderr) {...}`
Print the error message                 | `tf_printerr()`
Unset error state after handling        | `tf_unseterr()`

# Specifications

|                           |                                   |
| ------------------------- | --------------------------------- |
Specification pointer type  | `Specification *`
Parse/load specification    | `tf_specification_from_file(filename)`
Parse specification string  | `tf_parse_specification(string)`
Delete specification object | `tf_delete_specification(spec)`
List datatype names         | `dnames = tf_datatype_names(spec);`
                            | `dname = strtok(dnames, " ");`
                            | `while (dname != NULL) {`
                            | `...; dname = strtok(NULL, " ")}`
Preprocess specification    | `tf_preprocess_specification(infn, outfn)`
Check if preprocessed       | `tf_is_preprocessed(filename)`
Run tests in file           | `tf_run_specification_testfile(spec, testfn)`
Run tests in string         | `tf_run_specification_tests(spec, string)`

# Datatype definitions

|                           |                                   |
| ------------------------- | --------------------------------- |
Get a datatype definition   | `tf_get_definition(spec, datatype_name)`
Delete definition object    | `tf_delete_definition(ddef)`
Get verbose description     | `tf_describe(ddef)`

# Decoding, encoding and validating strings

|                             |                                   |
| --------------------------  | --------------------------------- |
Decode string to JsonNode     | `node = tf_decode(string, ddef)`
Decode string to JSON string  | `json = tf_decode_to_json(string, ddef)`
Encode from JsonNode          | `encoded = tf_encode(node, ddef)`
Encode from JSON string       | `encoded = tf_encode_json(string, ddef)`
Validate text format          | `boolvar = tf_is_valid_encoded(string, ddef)`
Validate JsonNode data for repr in text format | `boolvar = tf_is_valid_decoded(node, ddef)`
Validate JSON string for repr in text format   | `boolvar = tf_is_valid_decoded_json(string, ddef)`

# Decoding a file

|                                    |                                   |
| ---------------------------------- | --------------------------------- |
Decode file (wo embedded spec)       | `tf_decode_file(filename, false, ddef,`
                                     | `    decoded_processor_fn, decoded_processor_data,`
                                     | `    decoded_processor_level)`
Decode file with embedded spec       | `tf_decode_file(filename, true, ....`
Signature of decoded processor fn    | `void decoded_processor(JsonNode *n, void *data)`
Decoded processor levels             | 0: whole file/section;
(scope `file`/`section`)             | 1: element of compound definition;
                                     | 2: single lines
Set scope of definition              | `tf_set_scope(ddef, scope)`
where scope is (string):             | `line`, `unit`, `section` or `file`
Set unitsize (scope `unit`)          | `tf_set_unitsize(ddef, int nlines)`
Report branch of `one_of` definition | `tf_set_wrapped(ddef)`
(turn off branch wrapping)           | `tf_unset_wrapped(ddef)`

# JSON library

|                             |                                   |
| --------------------------  | --------------------------------- |
Data type for JSON nodes      | `JsonNode *`
                              |
Parse JSON string             | `node = jsonnode_from_string(string)`
Parse JSON file               | `node = jsonnode_from_file(filename)`
Emit JSON from node           | `jsonnode_to_string(node)`
                              |
Determine kind of a node      | `intvar = jsonnode_kind(node)` (0 to 6)
Scalar JSON node kinds        | `JNull` (0), `JBool` (1), `JInt (2),
                              | `JFloat` (3), `JString` (4)
Compound JSON node kinds      | `JArray (5)`, `JObject` (6)
                              |`
Create a scalar JsonNode      | `new_j_null()`, `new_j_bool(boolean)`,
                              | `new_j_float(float)`, `new_j_int(int)`,
                              | `new_j_string(string)`
Access scalar value           | `j_bool_get(node)`, `j_int_get(node)`,
                              | `j_float_get(node)`, `j_string_get(node)`.
                              |
Create an Array node          | `new_j_array()`
Query presence of an element  | `j_array_contains(array_node, query_element_node)`
Add an array element          | `j_array_add(array_node, node_element_to_add)`
Length of array               | `j_array_len(array_node)`
Get n-th element              | `j_array_get(array_node, n)`
                              |
Create an Object node         | `new_j_object()`
Add an object element         | `j_object_add(obj_node, key_string, node_to_add)`
Get element by key            | `j_object_get(obj_node, key_string)`.
Number of keys                | `j_object_len(obj_node)`
Get n-th key                  | `j_object_get_key(obj_node, n)`
Query presence of an element  | `j_object_contains(obj_node, query_element_node)`
                              |
Delete a node                 | `delete_jsonnode(node)`

