# TextFormats: Syntax of the specifications test data

Specification test data are examples of string representations and/or
data values which are valid and invalid according to the
datatype definitions of a specification.

## Testdata syntax

The test data can be stored in a file, which can be in JSON or YAML 1.2 format,
or constructed programmatically.

It must be a mapping, containing, under the root, a `testdata` entry.
Other entries are ignored: thus the same file can contain a
specification and the testdata, or they can be in different files.

The 'testdata' value is itself a mapping, where the keys are the names of the
datatypes to be tested and the values are mappings. These contain examples of
both valid and invalid string representations and decoded data can be given,
respectively, under the keys 'valid' (and `oneway`, see below) and 'invalid':
```YAML
testdata:
  datatype1:
    valid: ...
    invalid: ...
```

Valid data is given as a mapping under 'valid', where the keys are the encoded
string representations and the values are the decoded data:
```
valid: {"encoded1": "decoded1", ...}
```
The tests will both check that the encoded data is decoded as given, and
the opposite, i.e. that the decoded data is encoded as given.

Invalid data is given under the key 'invalid'. Under it, string
representations and decoded data are given as lists under, respectively,
the subkeys 'encoded' and 'decoded':
```YAML
invalid:
  encoded: ["3", ...]
  decoded: [3, ...]
```

As a particular case, if a datatype consists of strings, which are not
further processed (i.e. encoded and decoded form are the same), valid and/or
invalid strings can be conveniently just be imput as an array of strings:
```YAML
valid: ["string1", "string2", ...]
invalid: ["string1", "string2", ...]
```

### Non-canonical text representations

The content of `valid` shall be only string representations which
are obtained back when encoding the data they represent.
In some cases, only the decoding shall be tested, because the data
has a "non-canonical" string representation.
In this case a different key is used for listing the examples:
`oneway`.  Like under 'valid', the data is given as a mapping with
encoded string representations as keys and the decoded data as values:
```YAML
oneway: {"+2": 2, ...}
```
For data under 'oneway' only the decoding is tested, since this is not
the result which one would obtain from encoding the same decoded data.

For example a string representing a positive integer, can contain "2" which
will be decoded to the integer value 2. Reversing the operation, this value
would be encoded as the same string, i.e. containing "2". Also a
string with "+2" will be decoded to the same integer value 2. However, when
reversing the operation, this time the result of the encoding will be different
than the original string ("2" instead of "+2").

Thus, a both-ways test would fail:
```YAML
valid: {"2": 2, "+2": 2} # this would fail
```
When moving the canonical representation under oneway will the test will
succeed:
```YAML
valid: {"2": 2}
oneway: {"+2": 2}
```

## Running the tests of a specification

The test suite can be run using the `tf_spec` command-line tool (see the CLI
documentation) or using the API functions:

C
: `tf_run_specification_testfile` / `tf_run_specification_tests`
Nim
: `run_specification_testfile` / `run_specification_tests`
Python
: `specification.test()` / `specification.test(testfile)` /
  `specification.test({"testdata": {...}})`.

Note that different functions or arguments are available, for running tests which
are stored in a file, or constructed programmatically.

When the test suite is run, all datatypes for which tests are provided are
tested.  For each valid example, both decoding, encoding and validation of
decoded and encoded data are tested. For examples under `oneway`, only the
decoding and validation of encoded data are tested. For examples under
`invalid: decoded`, it is tested that encoding and validation of decoded data
fails, as expected. For examples under `invalid: encoded`, it is tested that
decoding and validation of encoded data fails, as expected.  In case one of the
expectations is not met, the test suite is interrupted with an error.

## Automatically generated test data

Test data can be written manually, according to the expectations about the kind
of data defined by a specification. Special cases (e.g. empty strings) shall
also be considered, when testing.

Besides writing tests manually, it is also possible to use the CLI tool
`tf_spec` to genererate tests. For this the Python `exrex` library must be
installed. The CLI documentation provides more information.

The automatically generated tests are, by definition, never failing. Thus it
does not make much sense to use them directly as a test suite (except for the
software developer testing the stability of results after code changes).
Instead, this functionality was implemented in order to automatically generate
examples of the definitions, which can be manually inspected by the user.  This
is very helpful, in order to check if a definition applies to text
representations and data values as intended, or something must be changed.

Furthermore, the user can manually edit or add data, thus using the generated
examples as a template for a test suite.

