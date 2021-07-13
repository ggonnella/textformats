# Format specifications syntax

The goal of the TextFormats library is to parse a textual representation
of data and translate it into data (decoding) and vice versa (encoding).
In order for the library to know how to access the data, the user
must describe the format of the textual representation and the rules used for
validating, decoding and encoding the data. This is done by writing a
specification.

A TextFormats specification is a mapping/dictionary. Its syntax is conceived
so to be representable as JSON (and YAML 1.2, which is a superset of JSON):
i.e. the mapping keys are strings, the values are mappings (with string keys),
arrays/lists, strings, numeric values, boolean values or null. Therefore it can
be stored in a JSON or YAML file, or constructed programmatically. Examples
in this file are given as YAML.

## Root level keys

The following keys at the top level of the specification mapping have
a defined meaning:
`datatypes`
: Definitions of the textual representations and parsing rules for the format
(whole data and/or its components)
`include`
: Specification files to be included in the current specification
`namespace`
: Prefix to be used when datatypes from this specification are
included in other specifications
`testdata`
: Examples of valid and invalid text representation and parsed data

Any other key at root level is ignored and reserved for use in future
versions.
A specification must contain at least a `datatypes` and/or an `include`
entry to be valid.
The syntax and purpose of each of the entries is explained in the
next sections.

## Organization of the specification

A format described in a TextFormats specification represents data where single
elements are scalar values: strings, integers, floating point numbers,
booleans, undefined values. These are usually combined to form compound values:
unordered sets, ordered sets, and/or sets where each element is associated to a
string key (the same kind of data, which can be represented as JSON).

The TextFormats specification explains how to translate back and forth between
the data and their textual representation in that format.  The single
components of the format (scalar or compound) are described in "datatype
definitions" given under the key `datatypes` of the specification mapping. The
datatype definitions for single elements can be combined together,
hierarchically, into compound elements.

## Entry "datatypes" under the specification root

The value of the `datatypes` entry under the root of a specification is a
mapping. Each of the entries of the `datatypes` mapping is a definition
of a 'datatype', i.e. a description and set of rules on how to parse a
textual representation of data.

For each of the entries under `datatypes`, the key is the "datatype name",
an identifier, which must be unique in the specification. The datatype
name starts with a letter and contains only letters, underscores
and numbers (regular expression: `[a-zA-Z][a-zA-Z0-9_]*`). Names are case
sensitive.

Each of the values of the `datatypes` entries is either:
- a mapping, giving a datatype definition; or
- a string, the name of another datatype

Thus, the structure of the `datatypes` mapping is e.g. as follow:
```YAML
datatypes:
  datatype_name_1: { ... }          # definition
  datatype_name_2: datatype_name_1  # reference, creates an alias
  ...
```

## Kinds of definition mapping

Mappings defining a datatype (rules for parsing a format element) are
found in the specification under the key `datatypes` (as stated above),
as well as "inline" definitions of the single elements of compound datatypes
(as explained below).

Each definition mapping contains exactly one "kind-of-definition key", as
well as a number of optional keys (some available for all definition kinds,
some specific).

Here is a list of the kind-of-definition keys, and a short description of the
the kind of values they allow to describe (details are in the following
sections):

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
: a value which may have different formats, described as separate
definitions

## Predefined datatypes

The following basic datatype definitions are predefined:

`integer`
: any signed integer (`+` sign is optional)
`unsigned_integer`
: any unsigned integer
`float`
: any floating point number
`string`
: any string
`json`
: inline JSON (i.e. without newlines)

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

## Definitions of kind "constant"

Constant definitions are used for elements of a format which have either only
one possible value (in some cases with multiple representations, as
described below), or two values, one in the case the element is present
and one in the case the element is absent (i.e. represented by an empty string).

The following table describes three possible contents of the key
`constant` and, depending on it, which non-empty text representation
(thereby `s` is a non-empty string) is valid and what is the decoded value:

| `constant` entry value | text representation | decoded value |
| ---                    | ---                 | ---           |
| string s               | s                   | s             |
| integer/float n        | any string representing n | n |
| mapping s (string): value v | s | v |

When the constant is a number, any valid text representation of the number is
accepted (e.g. "0.1" or "1E-1"). To accept only a single text representation
and still decode the value as number, a mapping is used (see example `c5`
below).

In the case of a mapping, there is a single entry, with a non-empty string key
`s`, and a value `v`, which can be anything representable in JSON (string,
number, boolean, null, mapping with string keys, list).

In case it is possible for the element to be absent from the text
representation, the optional key `empty` is used, where the value is the
decoded value to use in that case.

Here are examples of constant definitions:
```YAML
datatypes:
  c1: {constant: "1"}          # encoded: "1"; decoded: 1
  c2: {constant: "1": true}    # encoded: "1"; decoded: true
  c3: {constant: 1}            # encoded: "1" or "+1"; decoded: 1
  c4: {constant: 0.1}          # encoded: "0.1.", "1e-1", ...; decoded: 0.1
  c5: {constant: {"0.1": 0.1}; # encoded: "0.1"; decoded: 0.1
  c6: {constant: {"*": true}, empty: false}  # encoded: "*" or ""; decoded: t/f
```
For the cases where multiple text representation are accepted, the value
resulting from the encoding operation (termed _canonical_ text representation) is
the string returned by the `$` operator in Nim, applied to the decoded value
(e.g. "1" for 1; "0.1" for 1e-1)

## Definitions of kind "accepted values"

Definitions with kind-of-definition key `accepted_values` are used to
define a datatype, by which a finite (typically small) number
of textual representations are used to express a finite (typically small)
number of data values.

The content of the `accepted_values` key is a list of the possible values.
Each element of the list follows the same conventions as described above
for `constant`, i.e. it can be:

| `accepted_value` element value | text representation | decoded value |
| ---                    | ---                 | ---           |
| string s               | s                   | s             |
| integer/float n        | any string representing n | n |
| mapping s (string): value v | s | v |

Thereby strings (s) are non-empty. If, additionally, the absence of the element
shall be accepted (empty string), an entry is added to the
definition mapping, with the key `empty` and a data value, to be used in that
case.

In case a mapping is used for an element, it shall contain a single entry, with
a non-empty string key (textual representation) and any value, to be used as
data value for that textual representation.

Different definitions matching the same textual representation shall be avoided.
So e.g. in the following, the string "1"
would be decoded to "A", the string "+1" would be still accepted and decoded
to "B". But "B" would be encoded as "1", which in turn is decoded to "A".
```YAML
datatypes:
  avoid_this:
    accepted_values:
      - "1": "A"
      - 1: "B"
```

Here are examples of `accepted_values` definitions:
```YAML
datatypes:
  av1: {accepted_values: ["a", "b", "c"]}
  av2: {accepted_values: ["a", "1": "b"], empty: "c"}
  av3: {accepted_values: [1, 2, 3]}
```

## Definitions of kind `regex`

The definitions of kind `regex` are used for describing the value of
strings elements, for which the set of valid values is provided as
a regular expression.

The value of the `regex` entry is either a string (the regular
expression to be used) or a single-entry mapping,
where the key is the regular expression and the value is a JSON-representable
value (string, number, boolean, null, mapping with string keys, list),
which shall be used upon match.

Any regular expression accepted by the `regex` Nim library can be used.
The regular expression is internally edited to eliminate group names
(since named groups are used by the library for compound datatypes).

In the case a mapping {regex: value} is used for `regex`, the additional key
`canonical` shall be used.  This contains as value a string, which must match
the regular expression, and it defines which shall be the text representation
of the value used by the encoding functions.

If, additionally to matches of the regular expression, the absence of the
element shall be accepted (empty string), an entry is added to the definition
mapping, with the key `empty` and a data value, to be used in that case.
The `empty` rule has highest priority; thus it is used even if the regular
expression matches an empty string. For example in the example `r4` below,
if the element is absent in the textual representation, the decoded data
value will be the undefined value and not an empty string.

Here are examples of `regex` definitions:
```YAML
datatypes:
  r1: {regex: "\d{2,3}"}
  r2: {regex: {"[Tt](rue)?": true}, canonical: "True"}
  r3: {regex: {"(no|NO)": false}, empty: true, canonical: "NO"}
  r4: {regex: ".*", empty: null}
```

## Definitions of kind `regexes`

The definitions of kind `regex` are used for describing the value of
strings elements, for which the set of valid values is provided as
a set of regular expressions.

The value of the `regexes` entry is a list; each element of the
list is either a string (regular expression to use) or a single-entry
mapping with a string key (regular expression to use) to a JSON-representable
value to use as decoded value in case of a match of that regular expression.

If mappings are used as elements of the `regexes` list, then the `canonical`
entry shall be added to the definition. Given the mappings
[{r1: v1}, {r2: v2}...] under `regexes`, for each value v1, v2 ... there must
be an entry in `canonical` mapping {c1: v1, c2: v2...} where the keys are the
text representations to be used for encoding. They must be matches of the
corresponding regular expression (c1 matches k1, c2 matches k2 ...).

If an empty string shall be accepted, the key `empty` and a data value, to be
used in that case, shall be added to the definition.  The `empty` rule has
highest priority; thus it is used even if one of the regular expression matches
an empty string.

Here are examples of `regexes` definitions:
```YAML
datatypes:
  rs1: {regexes: ["\d{2,3}", "A", "x\dx"]}
  rs2: {regexes: {"[Tt](rue)?": true, "[Ff](alse)?": false},
                 canonical: {"True": true, "False": false}}
  rs3: {regexes: {"(no|NO)": 1, "(yes|YES)": 2}, empty: 3,
                 canonical: {"NO": 1, "YES": 2}}
```

## Definitions of kind `integer`

Definitions of kind `integer` are used for elements which have a numeric
integer value. The text representation must be in base 10 (unsigned integer
supports some other bases). Positive integers are optionally prefixed by "+".

The value of the `integer` key is a mapping; the validity range
can be specified, using the optional keys `min` and `max` in this mapping.
No other keys are supported.

The mapping under `integer` may be empty, if no validity range is specified.
If no other option of the definition mapping besides `integer` is used, the
definition mapping is `{integer: {}}`, which is equivalent to the predefined
datatype `integer` (but the latter is skipping range checks, thus may be faster
in the implementation).

If an empty string shall be accepted, the key `empty` and a data value, to be
used in that case, shall be added to the definition.

Here are examples of `integer` definitions:
```YAML
datatypes:
 i1: integer # predefined, equivalent to i2
 i2: {integer: {}}
 i3: {integer: {}, empty: 0}
 i4: {integer: {min: -10}}
 i5: {integer: {max: 100}}
 i6: {integer: {min: -10, max: 100}}
```

## Definitions of kind `unsigned_integer`

Definitions of kind `unsigned_integer` are used for elements which have a
numeric integer value >= 0. The text representation can be in base 10 (default),
base 2, base 8 or base 16. For the non-10 bases, underscores are ignored and
a prefix is accepted (but not required);
base 2: `0b`, `0B`; base 8: `0O`, `0o`; base 16: `0x`, `0X`, `#`. Base 16
letters (A to F) may have any case.

The value of the `unsigned_integer` key is a mapping; the validity range
can be specified, using the optional keys `min` and `max` in this mapping.
By default, `min` is 0 and `max` is the largest _signed_ integer. Note
that values between `INT64_HIGH` and `UINT64_HIGH` are not fully supported,
since they are not supported by the underlying JSON library.
The base is specified using the key `base`.

The mapping under `unsigned_integer` may be empty, if no validity range is
specified and the base is 10.  If no other option of the definition mapping
besides `unsigned_integer` is used, the definition mapping is
`{unsigned_integer: {}}`, which is equivalent to the predefined datatype
`unsigned_integer` (but the latter is skipping range checks, thus may be faster
in the implementation).

If an empty string shall be accepted, the key `empty` and a data value, to be
used in that case, shall be added to the definition.

Here are examples of `unsigned_integer` definitions:
```YAML
datatypes:
 u1: unsigned_integer # predefined, equivalent to u2
 u2: {unsigned_integer: {}}
 u3: {unsigned_integer: {base: 2}}
 u4: {unsigned_integer: {}, empty: 0}
 u5: {unsigned_integer: {min: 10}}
 u6: {unsigned_integer: {max: 100}}
 u7: {unsigned_integer: {min: 10, max: 100}}
 u7: {unsigned_integer: {min: 10, max: 100, base: 2}}
```

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
