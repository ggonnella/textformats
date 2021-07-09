# Format specifications syntax

A textformats specification is a mapping/dictionary containing datatype
definitions under the key "datatypes" and/or lists of specification
files to include under the key "include".

Further keys are optional; under "namespace" a prefix for the
datatype names is defined, which is used when the specification is included in
other; under "testdata" data for automatic testing, i.e. examples
of valid and invalid data can be added (see the Specification Tests manual).
Optionally, a specification can be embedded in a data file (see below).

The specification can be provided to the library functions as a JSON or YAML
string representation (Nim and C API), a dictionary (Python) or a
file in JSON, YAML or preprocessed specification format
(Nim, C, Python API and CLI).

## Datatype definitions section

The datatype definitions are given under the key "datatypes" of the
specification. The key contains a mapping, where the keys are the
names of the datatype, e.g.
```YAML
datatypes:
  a: ...
  b: ...
  c: ...
```

Each of the values is either:
- a mapping, giving a datatype definition, contain a definition key, as well as
further optional and/or required keys
- or a string, representing a reference to another datatype
  (see also section "References").

```YAML
datatypes:
  a: { .... } # definition
  b: a        # reference => "b" is an alias of "a"
```

The following sections explain how to define datatypes based on the value
they represent ("Datatype definition tutorial")
and give a systematic view of the syntax of datatype definitions
("Datatype definition syntax").

## Supported type of values

The supported type of values are:
- scalar values:
  - strings
  - numbers (integers, unsigned integers, float)
  - boolean and undefined values
- compound values:
  - lists (sequences / arrays)
  - dicts (tables / objects / structs / named tuples)

## Predefined datatypes

The following definitions are predefined:

`integer`
: any integer; positive integers can optionally have a + sign
`unsigned_integer`
: any unsigned integer
`float`
: any floating point number
`string`
: any string
`json`
: JSON (inline, i.e. without newlines)

The predefined datatypes can be used by defining aliases
to them or as elements in compound definitions:
```YAML
datatypes:
  a: integer
  b: {list_of: float, splitted_by: ","}
```

The predefined datatypes cannot be redefined, thus the following is an error:
```YAML
datatypes:
  string: {regex: "[0-9A-Za-z]+"} # ERROR: name "string" is reserved
```


## Datatype definition syntax

Datatype definitions are mappings, which contain exactly one definition
key, as well as further optional or required keys.

### Definition key

Here is a list of the definition keys, which are used to realize the
different datatype definitions:

`constant`
: only one possible value exists
`accepted_values`
: value is one of a set of possible values
`regex`
: a match of the provided regular expression
`regexes`
: a match of one of the provided regular expressions
`integer`
: an integer, optionally validated by a given range
`unsigned_integer`
: an unsigned integer, optionally validated by a given range
`float`
: a floating point value, optionally validated by a given range
`list_of`
: an ordered set of value, where the datatype and semantic
of the single elements does not depend by their position
`composed_of`
: an ordered set of values, where the datatype and semantic
of the elements depend on their position
`named_values`
: a set of key/value pairs, where the semantic and datatype of the
values depend on the key
`tagged_values`
: a set of tagname/typecode/value triples, where the semantic of the
value depend on the tagname and the datatype on the typecode
`one_of`
: any of a list of different possible datatypes

The `regexes` definition constructs internally a regular expression, with the
single regexes enclosed in '()' and contatenated using '|'. Thus the previous
case (where no further options are used), can also be expressed as
`regex` definition.
However, when using `regexes`, decoding rules can be applied separately for
each regular expression (see below).

Both `constant` and `accepted_values` construct internally the regular
expression, thus the previous cases (where no further options are used)
can also be expressed as `regex` or `regexes` definitions.

### Encoded value formatting and validation

Keys for `composed_of` and `list_of` definitions:

#### `splitted_by`
#### `separator`
#### `prefix`
#### `suffix`

For `named_values`:

#### `value_separator`

For `tagged_values`:

#### `internal_separator`
#### `tagnames`

### Decoded value validation

#### `min`, `max`, `min_excluded`, `max_excluded`
#### `length`, `max_length`, `min_length`

For `named_values`:

#### `single`
#### `required`

For `tagged_values`:
#### `predefined`

### Decoded value content

#### `as_string`
#### Decoding mappings
#### `canonical`
#### `empty`
#### `implicit`
#### `hide_constants`
#### `wrapped`

## `include`

## `namespace`

## `scope`

## `n_lines`
