# C API

The TextFormats library can be used in a `C/C++` program (including the Nim
library). A `C` API is provided for this purpose, and is contained in the
`C` subdirectory, in the `textformats_c.nim` file.

## Quick tutorial by examples

Assuming the specification file `myspec.yaml` contains:
```YAML
datatypes:
  mydatatype:
    list_of: unsigned_integer
    splitted_by: "--"
```

The following code example shows how to load the datatype from the specification
and use it for decoding and encoding data to/from JSON strings:

```C
#include <textformats_c.h>

int main() {
  NimMain() /* init Nim library */
  tf_quit_on_err = true; /* if any exception occurs, print msg and exit(1) */

  /* get the datatype definition */
  Specification *s = tf_specification_from_file("myspec.yaml");
  DatatypeDefinition *d = tf_get_definition(s, "mydatatype");

  /* convert to/from JSON strings */
  char *decoded = tf_decode_to_json("1--2--3", d);
  char *encoded = tf_encode_json("[1,2,3]", d);

  tf_delete_definition(d);
  tf_delete_specification(d);
  return 0;
}
```

To decode and encode data to/from binary C types, the provided wrapped to the
Nim json library is used.

The following example shows how to encode an array of ints to a string,
according to the definition of the `mydatatype` datatype:
```C
  size_t n_elems = 2, i;
  int elems[2] = [3,5];

  /* create a JArray JsonNode with the contents of the int array */
  JsonNode *array = new_j_array();
  for (i=0; i<n_elems; i++)
     j_array_add(array, new_j_int(elems[i]));

  /* encode the JArray using the datatype */
  char *encoded = tf_encode(array, d);
  delete_jsonnode(array);

  /* do something with the resulting string... */
  printf("Encoded: %s\n", encoded);
```

The following example shows how to decode a string, encoded as by definition of
the `mydatatype` datatype, to an array of int:
```C
  /* decode the string to a JArray JsonNode */
  JsonNode *array = tf_decode("1--2--3", d);

  /* create an int array with the contents of the JArray */
  size_t n_elems = len(array), i;
  int *elems = malloc(n_elems*sizeof(int));
  for (i=0; i<n_elems; i++) {
    JsonNode *elem = j_array_get(array, i);
    elems[i] = j_int_get(elem);
    delete_jsonnode(elem);
  }
  delete_jsonnode(array);

  /* do something with the resulting int array... */
  for (i=0; i<n_elems; i++)
     printf("Element %i = %i\n", i, elems[i]);
  free(elems);
```

## Compiling a program based on the C API

The Makefile provided in the `C/examples`, `C/tests` and `C/benchmarks`
directories contain examples on how to compile a C program based on TextFormats.
Note that the NIMLIB variable (path to the NIM library directory) must be set
by the user[^1].

The TextFormats wrapper for C is written in Nim and compiled using `nim c` with
the flags `--noMain --noLinking --header:textformats_c.h --nimcache:$NIMCACHE`,
where $NIMCACHE is the location where the compiled files will be stored.

The API is then included into the C file (`#include "textformats_c.h"`) and
linked using the following compiler flags before the name of the C file to
compile: `-I$NIMCACHE -I$NIMLIB $NIMCACHE/*.o` where NIMLIB is the location of
the NIM library[^1].

In the C code, the Nim library must be initialized calling the function
NimMain().

[^1] If you use choosenim for managing Nim versions, the location of the
library will be in the choosenim directory (default: ~/.choosenim) under
toolchains/nim-$VERSION/lib where $VERSION is the version of Nim you are
using (e.g. 1.4.8).

## Error state

A runtime error can result from calling any of the API functions.
In case the Nim code raises an exception, the C code must decide
how to react. Two ways of handling errors are provided.

### Quitting the program after any error

The easies way to handle errors is to print an error message to
the standard output and quit the program in case of any error.
For this behaviour, just set the global variable `tf_quit_on_err`
to `true`.

### Handling errors

In alternative, it is possible to decide case-by-case if, after an API call
which resulted in an error, the program shall be quit or the error should
be handled.

For this behaviour, after function calls for which the program shall be quit
in case of error, call the function `tf_checkerr()`

For functions, for which the error state shall be handled, the global
variable `tf_haderr` is checked. The error message can be printed using
`void tf_printerr()`.
The kind of error (e.g. "DecodingError") is stored as string
in the variable `tf_errname`.
After handling the error, the error state is cleared calling the function
`void tf_unseterr()`.

Example code:
```C
encoded = tf_encode("[1,2,3]",d);
/* exit program if the above fails */
tf_checkerr();

decoded = tf_decode("[1--2--3]",d);
/* handle the error if the above fails*/
if (tf_haderr) {
  decoded = default_value;
  printf("Error while decoding the value, the default will be used instead\n");
  tf_printerr();
  tf_unseterr();
}
```

## Specifications

The function `Specification* tf_specification_from_file(char *filename)` is
used to parse a YAML specification or load a preprocessed specification and
get a pointer to the specification, which can be passed to other functions.

Alternatively a specification can be constructed using a JSON or YAML string
as argument of `Specification* tf_parse_specification(char *specdata)`.

The latter can be combined with the `jsonwrap` functions (see below) to create
the specification programmatically, e.g.:
```C
JsonNode
  *specdata = new_j_object(), *datatypes = new_j_object(),
  *mydatatype = new_j_object(),
  *list_of_value = new_j_string("unsigned_integer"),
  *splitted_by_value = new_j_string("--");

j_object_add(mydatatype, "list_of", list_of_value);
j_object_add(mydatatype, "splitted_by", splitted_by_value);
j_object_add(datatypes, "myspecdata", myspecdata);
j_object_add(specdata, "datatypes", datatypes);

Specification *spec = tf_parse_specification(jsonnode_to_string(specdata));

jsonnode_delete(specdata);
jsonnode_delete(datatypes);
jsonnode_delete(mydatatype);
jsonnode_delete(list_of_value);
jsonnode_delete(splitted_by_value);
```

The function `void delete_specification(Specification *spec)` is used after
the last access to the specification, to inform the Nim garbage collector
that no reference to it is needed anymore.

### List of datatype names

To output the names of the datatypes defined by a specification,
use the `char* datatype_names(Specification *spec)` function.
The datatype names are space-separated.

Example usage:
```C
// requires #include <string.h>
char *dnames = tf_datatype_names(spec);
char *dname = strtok(dnames, " ");
while (dname != NULL) {
  printf("%s\n", dname);
  dname = strtok(NULL, " ");
}
```

### Preprocessing

It is possible to preprocess a YAML specification using the function
`void tf_preprocess_specification(char *inputfile, char *outputfile)`.
To check if a specification is preprocessed, the function
`bool tf_is_preprocessed(char *filename)`
can be used (this does not ensure that the file has valid
content, it only checks if the initial signature of preprocessed
specification files is present).
The suggested file extension for preprocessed specifications
is `tfs` (*T*ext*F*ormats *S*pecification).

### Running tests

It is possible to run a test suite for a specification using the function
 `void tf_run_specification_testfile(Specification *spec, char *testfile)`.
Alternatively, it is possible to provide the testdata as a string
in JSON or YAML format, using
`void tf_run_specification_tests(Specification *spec, char *testdata)`.

In case the test is unsuccessful, the `tf_haderr` flag is set.

## Datatype definitions

To obtain a datatype definition from a specification, use
the function
`DatatypeDefinition* tf_get_definition(Specification *s, char* dtype_name)`.
The returned pointer is then passed to other API functions.
Once it is not used anymore, it is possible to communicate this fact to
the Nim Garbage Collector using the function
`void tf_delete_definition(DatatypeDefinition* dd)`.

A verbose textual description of the content of the definition is obtained
using `char* tf_describe(DatatypeDefinition* dd)`.

## Decoding the string representation of data

The functions `JsonNode* tf_decode(char *encoded, DatatypeDefinition* dd)`
and `char* decode_to_json(char *encoded, DatatypeDefinition* dd)` are used to
decode a string which follows the given datatype definition to, respectively,
a `JsonNode` (from which the binary data can be obtained, using the
provided wrapper to the Nim `json` library, see below) or a string,
representing the data as JSON.

### Encoding data to their string representation

The functions `char* tf_encode(JsonNode *node, DatatypeDefinition *dd)`
and `char* encode_json(char *json, DatatypeDefinition *dd)` are used
to encode data using the given datatype definition, from, respectively, a
`JsonNode` (created using the provided wrapper to the Nim `json`
library, see below) or a string,
representing the data as JSON.

## Validating data or their string representation

If is only necessary to know if encoded or decoded data follow a
datatype definition, and no access to the result of decoding or encoding is
necessary, the validation functions can be used. Depending on the datatype
definition, they can be faster than full decoding or encoding.

The function `bool tf_is_valid_encoded(char *encoded, DatatypeDefinition* dd)`
can be used to validate an encoded string.

The functions `bool tf_is_valid_decoded(JsonNode *node, DatatypeDefinition* dd)`
and `bool tf_is_valid_decoded_json(char *json, DatatypeDefinition* dd)` are used
to determine if the data could be validly represented using the definition.
The data is provided as, respectively,
a `JsonNode` or a string representing the data as JSON.

## Decoding a file

To decode a file, the following function is used:
```C
void tf_decode_file(char *filename, bool skip_embedded_spec,
                    DatatypeDefinition* dd,
                    void decoded_processor(JsonNode *n, void *data),
                    void *decoded_processor_data,
                    int decoded_processor_level)
```

Thereby the file is decoded into one or multiple values, which are passed
to the `decoded_processor` function. Further data can be passed to
the same function, by providing a pointer to it (`decoded_processor_data`).

For example after passing a `FILE*` as `decoded_processor_data`,
 the `decoded_processor` could be something like:
```C
void decoded_processor(JsonNode *int_node, void *data) {
  FILE *file = (FILE*)data;
  fprintf(file, "%i\n", j_int_get(int_node));
}
```

### Embedded specifications

The `bool` parameter `skip_embedded_spec` of `tf_decode_file` is set to `true`,
if the data and the specification are contained in the same file. A data
file may contain an embedded YAML specification, preceding the data and
separated from it by a YAML document separator line (`---`). In this case
the file decoding function must know that it shall skip the specification
portion of the file while decoding (thus the parameter must be set).

### Level of application of the decoded processing function

Definitions at `file` or `section` scope are compound datatypes (`composed_of`,
`list_of` or `named_values`), which consist of multiple elements (each in one
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

The parameter `decoded_processor_level` of `tf_decode_file` is used to
control what part of the decoded value is passed to the `decoded_processor`
function: 0, for `whole`, 1 for `element`, 2 for `line`.
Further parameters are the processing function
(`decoded_processor`), which is applied to each decoded value (at the selected
level), and a void pointer `decoded_processing_data`, which is passed to the
processing function, in order to provide to it access to any further necessary
data.
For scope `line` and `unit` the `decoded_processor_level` parameter is ignored.

### Scope of the definition

In order to use a definition for decoding a file, a scope must be provided.
This determines which part of the file shall be decoded applying the definition.
The scope can be provided directly in the datatype definition and must be
"line", "unit" (constant number of lines), "section" (part of the file, as long
as possible, following a definition; greedy) or "file".

The scope of a definition can also be set using the C function:
`void tf_set_scope(DatatypeDefinition *dd, char *scope)`, where scope is a
string containing one of the above values.

If the scope is set to `unit`, the number of lines of a unit must be set,
either in the datatype definition, or using
`void tf_set_unitsize(DatatypeDefinition *dd, int n_lines)`.

### Reporting the branch of "one of" used by decoding

When a `one_of` definition is used for decoding, it is possible to set the
decoded value to contain information about which branch was used for the
decoding. This can be set either setting the key `wrapped` in the
datatype definition, or by using the function
`void tf_set_wrapped(DatatypeDefinition *dd)`
(and `void tf_unset_wrapped(DatatypeDefinition *dd)` for unsetting the flag).

## Wrapper to the Nim `json` library

The `JsonNode` structure is used to represent the binary data which is passed
to the TextFormats encoding functions or obtained as a result from the
TextFormats decoding functions. `JsonNode` are scalars or compound values
and can represent all the data which can be represented in a Json file.

Scalar JsonNode are one of 5 kinds
 `JNull` (NULL value), `JBool`
(boolean values), `JInt` (largest signed integer type),
`JFloat` (double precision floating point values) or `JString` (strings).

Two compound kind of nodes are available.
Arrays of JsonNode elements (and thus of potentially heterogeneous data) are
of the kind `JArray`. Hash tables of strings to JsonNode elements
(also in this case of potentially heterogenous data) are of the kind
`JObject`.

### Creating JsonNode instances

To create a JsonNode, the functions `JsonNode *new_<kind>()` are used.
`JsonNode *new_j_null()`, `JsonNode *new_j_bool(bool b)`,
`JsonNode *new_j_int(int i)`, `JsonNode *new_j_float(double f)`,
`JsonNode *new_j_string(char *s)` are used for creating scalar JsonNode.

To create an array, `JsonNode *new_j_array()` is used, which returns
an empty array, to which elements are added using
`void j_array_add(JsonNode *array, JsonNode *element_to_add)`.

To create a table, `JsonNode *new_j_object()` is used, which returns
an empty table, to which key/value pairs are added using
`void j_object_add(JsonNode *table, char* key, JsonNode *value)`.

JSON code can be parsed to a JsonNode instance using
`JsonNode *jsonnode_from_string(char *string)` or, if in a file,
using `JsonNode* jsonnode_from_file(char *filename)`.
JSON code representing a JsonNode can be constructed
using `char* jsonnode_to_string(JsonNode *n)`.

Once a JsonNode instance is not used anymore, it can be marked for deletion
using `void delete_jsonnode(JsonNode *n)`

### Accessing the data of a JsonNode

The kind of a node can be determined using
`int jsonnode_kind(JsonNode *n)` which returns one of the following `int` values
(not an enum due to limitations of the C headers generator):
0 (JNull), 1 (JBool), 2 (JInt), 3 (JFloat),
4 (JString), 5 (JArray) or 6 (JObject).

The value of a scalar node, can be accessed using one of:
`bool j_bool_get(JsonNode *n)`, `int j_int_get(JsonNode *n)`,
`float j_float_get(JsonNode *n)`, `char* j_string_get(JsonNode *n)`.

The number of entries in a array node can be obtained using
`int j_array_len(JsonNode *n)`. The entries are obtained using
`JsonNode *j_array_get(JsonNode *n, int index)`.
Assessing if an array contains an element can be done using
`bool j_array_contains(JsonNode *n, JsonNode *element)`.

The number of keys in a object node can be obtained using
`int j_object_len(JsonNode *n)`. The keys are obtained using
`char *j_object_get_key(JsonNode *n, int index)`.
The values can be obtained using
`JsonNode* j_object_get(JsonNode *n, char *key)`.
Assessing if an object contains an entry for a key can be done using
`bool j_object_contains(JsonNode *n, char *key)`.

## Note on C string pointers

Since the `cstring` type used in the API is handled in Nim as a non const
pointer, strings such as filenames, encoded data, decoded JSON data are
`char*`. Nevertheless, the strings are not modified by the functions.
Thus `const char*` can be used and, when required, explicitely casted
to `char*`.

