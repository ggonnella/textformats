# Developer manual

The present text describes the current organization of the source code,
as well as current conventions used in it.

## Library code

The Nim code is located under the directory `src`. The public API
is defined by the module `src/textformats.nim`. The module only contains
import and export statements.

The rest of the code is located
in the subdirectory `src/textformats`. This organization is the one
required by the Nimble package manager.

### Support modules

Generic modules (data structures, helper methods) independent from
the rest of the library are implemented under the directory
`src/textformats/support`. By convention, they are not allowed
to import anything from the library outside of this directory.

### Types

Types are defined under `src/textformats/types`. This includes
the types for specification, datatype definitions and the errors.
All keys used in the specifications are stored as constants
under `src/textformats/types/def_syntax.nim`

### Main functionality

Modules which define the main functionality of the library are directly
found under `src/textformats`.

### Datatypes

The implementation of the operations for each of the datatypes
is provided in modules under `src/textformats/dt_<DATATYPE_NAME>`.
Each of the contained modules is named `dt_<DATATYPE_NAME>_<OPERATION>`.

### Shared

Code common to multiple datatypes (e.g. due to common options)
is provided under the directory `src/textformats/shared`.

### CLI

The code for the CLI tools is under `src/textformats/cli`. The tools
are compiled by calling `nimble build`. Their manuals
are provided as Markdown in the same directory and are compiled to
`man` manuals using `nimble climan`. For this `pandoc` must be installed.

The CLI tools are based on `cligen`. Multiple dispatching is used, thus
after the binary name the user will need to input the subcommand as first
argument. The other available arguments depend on the subcommand. Some
are required, but they are all provided as `--options/-o` because of
limitations of `cligen`.

However, default values are provided whenever possible.
In all cases, if a datatype name is not provided, the dataype name
"default" is used. If a test file is not provided, the testdata in the
specification are used. If no specification by decoding files
is provided, then an embeddded specification is assumed. If input
files or strings are not provided, the standard input is used.

In order to have the same short option code and help text for the same option
across the tools and subcommands, they are all defined in the module
`cli_helper`. This also defines a `exit_with` template, to exit
the program in case of error, as well as common error codes and messages.
Also functions for obtaining a specification and/or datatype definition
from the command line arguments are defined in it.

## Tests

The test suite is provided under `tests` and is called using `nimble test`.

## Python API

The Python API is located in the directory `python`. The directory is structured
as a Python pip package, defined in the `setup.py` file, which requires
the `nimporter` pip package.
Benchmarks are provided under `benchmarks`, systematic code tests under
`tests` and example code under `examples`.

The `Makefile` has the default goal of compiling and installing the package.
It also has other goals to create a source or binary wheel.

## C API

The C API is located in the directory `C`.
It contains 3 Nim modules, which make use of `{.exportc.}` pragma.
Benchmarks are provided under `benchmarks`, systematic code tests under
`tests` and example code under `examples`.

### Error handling module

Each of the exported `proc` also use the `raises = []` pragma in order
to make sure that all exceptions are caught before returning to the C side.
Error handling is done in the module `error_handling.nim`. The provided
templates are used in all exported `proc`, if they can raise any exception.

### Json library wrapper

`JsonNode` of the `json` Nim library is used to be able to represent dynamic
values, such as those resulting from the decoding, or passed as an input to the
encoding functions.  The provided `jsonwrap.nim` module contains wrappers to
most functions of the `json` module.

Comments at the end of the file document the functions of `json` which
were not wrapped. The functions have slightly different naming conventions than
in the `json` library. However, in order to avoid name clashes (e.g. of the
JsonNode type, see below), the json library is imported using
`from json import nil`.

Unfortunately Nim enums cannot be exported, which causes e.g. the
`jsonnode_kind` function to return an `int` instead of an enum value.
For this reason there is a `jsonkind.h` header in the `tests` directory,
which defines the enum values as preprocessor constants.

The C code does not require to explicitely include this module, since
it is exported by the `textformats_c` module.

### TextFormats C API module

The API functions and types are provided by the `textformats` module.
Each function has a prefix `tf_`, and otherwise follows the same conventions
as the Nim API.

Instead of an iterator for decoding a file, the C API uses the
function `decode_file`, which is exported for this purpose.
The function takes a function pointer (and a void pointer to provide extra data
to the function). The function is called on each of the decoded elements
from the file.

### Making types visible in C

In order to make the names of the Nim types visible in C,
the following system is used. The type to be exported (using `{.exportc.}`)
is defined as object (e.g. `JsonNode`) which contains a single member
`value`, which has the original Nim type (e.g. `json.JsonNode`).
Futhermore a reference to this type is defined, with the same name plus a
 suffix `Ref` (e.g. `JsonNodeRef`). The references are then used
in the function interface. Thus in C they will be visible as pointers
to the exported type (e.g. `JsonNode*`).

Thus part of each functions in the C API modules is to get or set the `value`
member of the input or result, which is obtained by or in order to pass it to
the original Nim function.

The system is used for the `DatatypeDefinition` and `Specification` types
in `textformats_c` and for `JsonNode` in `jsonwrap`.

### Header flag

The limitations regarding type export, as well as the impossibility to export
enums, arises from the fact that the `--header` flag of `nim` is not
accepted by part of the Nim developers, including the project head. They
suggest instead of using it, to generate the header from the C file, if
necessary.

Nevertheless the flag is not officially deprecated (yet) and it is
even referred to in the official documentation of the Nim Backend Integration.
(https://nim-lang.github.io/Nim/backends.html).
Until then, it will be thus be used for the C API.
