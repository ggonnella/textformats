## Testing a specification

### Testdata YAML syntax

The test data for a specification, either manually or automatically generated,
is written in YAML format. It can be written in the same file as the
specification itself, or in a separate file.

As for the specification, the YAML document (which must be the first YAML
document in the file) must contain a mapping. Test data are written
under the key 'testdata' under the mapping root.

The 'testdata' key contains a mapping, where the names of the datatypes to be
tested are the keys. Each of the datatype keys contain a mapping, where
examples of both valid and invalid textual representations and decoded data can
be given, respectively under the keys 'valid' and 'invalid':
```YAML
testdata:
  datatype1:
    valid: ...
    invalid: ...
```

#### Examples of valid data

Valid data is given as a mapping under 'valid', where the keys are the encoded
textual form and the values are the decoded data:
```
valid: {"encoded1": "decoded1", ...}
```
The tests will both check that the encoded data is decoded as given, and
the opposite, i.e. that the decoded data is encoded as given.

#### Examples of invalid data

Invalid data is given under the key 'invalid'. Under it, textual
representations and decoded data are given as lists under, respectively,
the subkeys 'encoded' and 'decoded':
```YAML
invalid:
  encoded: ["3", ...]
  decoded: [3, ...]
```

#### Testing invariant string datatypes

As a particular case, if a datatype consists of strings, which are not
further processed (i.e. encoded and decoded form are the same), valid and/or
invalid strings can be conveniently just be imput as an array of strings:
```YAML
valid: ["string1", "string2", ...]
invalid: ["string1", "string2", ...]
```

#### Testing non-canonical textual representations

In some cases, however, only the decoding shall be tested, because the data
has a "canonical" textual representation (obtain by encoding), but further
representations are valid as well, and can be decoded.

Another mapping key ('oneway') is used for handling tests of these non-canonical
representations. Like under 'valid', the data is given as a mapping with
encoded string representations as keys and the decoded data as values:
```YAML
oneway: {"+2": 2, ...}
```
For data under 'oneway' only the decoding is tested, since this is not
the result which one would obtain from encoding the same decoded data.

##### Example of testing non-canonical representations

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

