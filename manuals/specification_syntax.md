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

## Datatype definition tutorial

The following sections explains how to define datatypes,
based on the type of values they represent.

The supported type of values are:
- scalar values:
  - strings
  - numbers (integers, unsigned integers, float)
  - boolean and undefined values
- compound values:
  - lists (sequences / arrays)
  - dicts (tables / objects / structs / named tuples)

For each of the type of values, it is exlained how to specify specify the
string representation formatting, rules for the validation of the decoded
values, and for the decoding of the string representation.

### Strings

The following definitions handle values which shall be decoded as
either unchanged or modified strings.

The predefined `string` datatype can be used, if any string is accepted.

If only one or one of a list of possible values are allowed, then,
respectively, a `constant` or `accepted_values` definition can be used:
```YAML
datatypes:
  string3: {constant: "XYZ"}
  string4: {accepted_values: ["ABC", "DEF"]}
```

If a string must match a given regular expression, a definition of kind
`regex` or `regexes` (multiple regexes are automatically concatenated)
can be used:
```YAML
datatypes:
  string1: {regex: "[ABC]{1,3}"}
  string2:
    regexes:
    - "[ABC]{1,3}"
    - "[DEF]{5,7}"
```

#### Validation of a string by datatype definition

In some cases, although a value shall be decoded as string, and not further
parsed into smaller elements, its format is quite complex.

In this case it can be useful to create a definition (e.g. for a compound
datatype, as explained below) and then let Textformats know that the
definition shall only be used for validation, but not for parsing,
using the `as_string: true` option.

For example the following definition of a string (containing unsigned
integers and '.' separating them) uses a relatively complex regular expression:
```YAML
datatypes:
  string5:
    regex: "(0|[1-9][0-9]*)(\.(0|[1-9][0-9]*))*"
```

The following definition is equivalent, but more readable:
```YAML
datatypes:
  string6:
    list_of: {regex: unsigned_integer}
    splitted_by: "."
    min_length: 1
    as_string: true
```

#### Modified decoded strings

By default, values which should result in string are just encoded
as the string itself, i.e. there is only validation, but no parsing or
modification of the value.

In some cases, a different string value is required, than the encoded one.
First, a value can be specified for empty strings. Furthermore one can
create a mapping of encoded to decoded values: e.g. one could want to expand an
acronym. Caveat: if multiple encoded values are decoded
to the same decoded value (always for regular expressions), then canonical
encoded forms must be specified, so that the encoder knows which one shall be
used. Examples:
```YAML
datatypes:
  string7:
    accepted_values:
      - "USA": "United States of America"
      - "UK": "United Kingdom"
  string8:
    accepted_values:
      - "USA": "United States of America"
      - "UK": "United Kingdom"
    empty: "Worldwide"
  string9:
    regexes:
      - "U(SA?|sa)": "United States of America"
                     # USA, US, Usa are all accepted
      - "U[Kk]": "United Kingdom"
    canonical:
      - "USA": "United States of America"
      - "UK": "United Kingdom"
```

### Numerical values

The following definitions handle values which shall be decoded as
numerical values.

The predefined `integer`, `unsigned_integer` and `float` datatypes
are used for numerical values where every valid value shall be accepted.

If only a single value or a value in a given set of values shall be accepted
a `constant` or, respectively, `accepted_values` definition is used:
```YAML
datatypes:
  num1: {constant: 3}
  num2: {accepted_values: [1,2,3]}
```

If only values in a given range are accepted, `min` and/or `max` can
be used; the default is to include the limits in the accepted values,
but they can be excluded using `(min|max)_excluded`:
```YAML
datatypes:
  num3: integer: {min: -1, max: 1}
  num4: unsigned_integer: {min: 0, max: 100}
  num5: float: {min: 0, max: 1}
  num6: float: {min: 0, min_excluded: true, max: 1, max_excluded: true}
```

#### Specially formatted numbers

In general, there is no special support for numbers formatted unconventially.
That is, they must be validated as strings and the conversion to/from numbers
is then done in the calling code. An exception are cases in which there is
a limited number of values, for which the textual representations
can be simply enumerated:
```YAML
datatypes:
  num7:
    accepted_values:
      - "I": 1
      - "II": 2
      - "III": 3
```

### Boolean and undefined values

The following definitions handle values which shall be decoded as
boolean values and/or undefined values.

In these cases, one or multiple string valid representations exist
for each of the decoded values. These can be provided using
an `accepted_values` definition and a mapping. If multiple encodings
are possible, `canonical` representations must be choosen
(always if regexes are used):
```YAML
datatypes:
  boolean1:
    accepted_values: ["T": true, "F": false, "NA": null]
  boolean2:
    regexes:
      - "[Tt](rue)?": true
      - "[Ff](alse)?": false
    canonical: {"T": true, "F": false}
```

In some cases, a boolean value is encoded as the presence or absence
of a given element. In this case a `constant` definition with a default
value (`empty` key) can be used:
```YAML
datatypes:
  boolean3:
    constant: {"$": true}
    empty: false
```

### Lists/sequences/arrays

The following definitions handle values which shall be decoded as
ordered sets of elements, where the datatype and semantic of an element does not
depend on its position. Depending on the language and implementation,
such sets are named and/or represented differently:
lists, sequences and/or arrays.

For such cases, the definition of the elements is given, under the `list_of`
key:
```YAML
datatypes:
  list1:
    list_of: {regex: [A-Z]}
```

#### Formatting

Often the parsing is made possible by a separator string between the elements,
which does not occur in the elements itself. This is specified using
the key `splitted_by`:
```YAML
datatypes:
  list2:
    list_of: unsigned_integer
    splitted_by: ","
```

In some cases, however, the separating string can also be present in the
elements itself, e.g. by escaping it. In this case the `separator` key
is used, and a e.g. a regular expression is used:
```YAML
datatypes:
  list3:
    list_of:
      regex: "(\\\:|[A-Za-z0-9 _])*"  # allows : escaped by \
      separator: ":"                  # e.g. elem 1:elem2:elem_3:elem\:\:4

```

Another case for `separator` is where the separating string could be present
in the elements and the elements length is constant, e.g.
```YAML
datatypes:
  list4:
    list_of:
      regex: "[.0-9]{3}"   #      <-> <-> <-> <-> <-> <-> (length 3)
      separator "."        # e.g. 001.0...002.2.1.112....
```

In some cases, before the first and/of after the last element a
prefix/suffix is present, e.g.:
```YAML
datatypes:
  list5:
    list_of: unsigned_integer
    splitted_by: ","
    prefix: "("
    suffix: ")"       # e.g. (1,2,3,4)
```

#### Validating the number of elements

In some cases there is a minimum and/or maximum or a fixed number elements
of the list. This can be enforced:
```YAML
datatypes:
  list6:     # e.g. 0;-1;32
    list_of: integer
    splitted_by: ";"
    length: 3
  list7
    list_of: integer
    splitted_by: ";"
    min_length: 5
    max_length: 7
```

Empty lists are also supported. If there is no prefix and suffix, then
its representation is an empty string; in this case, use the `empty` key:
```YAML
datatypes:
  list8:
    list_of: {regex: "[A-Z]"}
    empty: []
```
#### Special lists representations

Using decoding mappings is it possible to decode given strings to lists. E.g.
```YAML
datatypes:
  list9:
    accepted_values:
      "1a": ["a"]
      "2a": ["a", "a"]
      "3a": ["a", "a", "a"]
    empty: []
```

### Tuples/tables/dictionaries/objects

The following definitions handle values which shall be decoded as
sets of elements, where the datatype and semantic of the elements varies.
Depending on the language and implementation, such sets are named and/or
represented differently: as dictionaries, mappings/maps, (hash) tables,
objects, structs, named tuples.

The semantic and datatype of the elements can be encoded in different
ways in the string representation. From this it depends which
definition kind shall be used.

#### Fixed order of the elements

In cases a sequence of element is represented, in which the position of the
elements in the sequence determines their semantic and datatype, a
`composed_of` definition is used. This gives a name and definition for
each of the elements, as a sequence:
```YAML
datatypes:
  dict1:
    composed_of:
      - first: unsigned_integer
      - second: float
      - third: {regex: "[A-Za-z0-9]"}
    splitted_by: " "
```
As for lists (see previous section), the `splitted_by`, `separator`,
`prefix` and/or `suffix` keys can be used to specify the formatting
and how to parse the elements.

In some cases, different separators are used between different pairs of
elements. In this case, they can be specified as additional elements
and hidden in the decoded dictionary using `hide_constants`:
```YAML
datatypes:
  dict2:          # e.g. 1;2.0|A <-> {x: 1, y: 2.0, z: A}
    composed_of:
      - x: unsigned_integer
      - sep1: {constant: ";"}
      - y: float
      - sep2: {constant: "|"}
      - z: {regex: "[A-Za-z]"}
    hide_constants: true
```

Some of the elements can be allowed to be absent from the sequence
of elements. Two cases can be distinguished. In the first case, the
sequence is splitted by a non-empty separator string; thus an empty
element can be recognized by the presence of this separator. In this
case `empty` keys are used in the elements definitions:
```YAML
datatypes:
  dict2:            # e.g. ;B <-> [0, "B"]
    composed_of:
      - first: {accepted_values: [1,2], empty: 0}
      - second: {accepted_values: [A,B], empty: C}
    splitted_by: ";"
```

In the second case, the first elements of the sequence may be mandatory,
while the following can be present or not (and are mandatory only
if elements after them in the order are present). In this case, the
`n_required` key is used:
```YAML
datatypes:
  dict3:            # e.g. 1 <-> [1, "C"]
    composed_of:
      - first: {accepted_values: [1,2], empty: 0}
      - second: {accepted_values: [A,B], empty: C}
    splitted_by: ";"
    n_required: 1
```

If one of the internal elements, together with its associated separator,
is allowed to be missing, multiple alternative definitions shall be provided
(with and without the optional internal element). An example is given in
the "implicit keys" section below.

#### Elements accompanied by a key

In case a elements are represented in a non-fixed order, the semantic
and datatype of the elements is sometimes given as a key preceding
the value. The set of possible keys is known in advance. In this case
a `named_values` definition is used:
```YAML
datatypes:
  dict4:
    named_values:
      rank: unsigned_integer
      name: string
    splitted_by: ";"
    value_separator: ":"
```
The keys and the datatypes of the associated values are given under
the `named_values` key, as a mapping.
Note that a `value_separator` string must be specified, separating the key
from the value. The separator cannot occur in the keys, but it can occur
in the values.

Names are by default allowed to present multiple times in the list. For
this reason, the elements values are always given in the decoded value as lists.
In some cases, all or some of names can only be present once. This can
be enforced by listing them under the `single` key:
```YAML
datatypes:
  dict5:
    named_values:
      rank: unsigned_integer
      name: string
    splitted_by: ";"
    value_separator: ":"
    single: [rank, name]
```

Also, by default, some names may be absent in the set of elements. If some
of the names must be present, they are listed under the `required` key:
```YAML
datatypes:
  dict6:
    named_values:
      rank: unsigned_integer
      name: string
    splitted_by: ";"
    value_separator: ":"
    required: [name]
```

#### Elements accompanied by a name and typecode

Another possible representation are tags. In this case values are given
in a non-fixed order, and are each accompanied by a name and typecode,
which define, respectively, the semantic and the datatype of the values.
Using tags, the names (semantics) of the elements must not all be already
known when specifying the format. For tags, the `tagged_values` definitions
are used:
```YAML
datatypes:
  dict7:  # e.g. A.i.12;B.f.1.3 <-> {"A": 12, "B": 1.3}
    tagged_values:
      i: integer
      f: float
    tagname: "[A-Z]"
    internal_separator: "."
    splitted_by: ";"
```
All available datatypes codes and the associated datatype definitions
are given under the `tagged_values` key as a mapping.
Furthermore the names formatting/validation is specified using
a regular expression. The internal separator key is mandatory and
the string cannot be present in tagnames and type codes.

#### Implicit values

In some cases, the decoded dictionary shall contain a given constant
key/value pair, which is not explicitely encoded. These are specified
using the `implicit` mapping, which is available for `composed_of`,
`named_values` and `tagged_values` definitions:
```YAML
  dict9:
    composed_of:   # e.g. "16S,2" <-> {"name": "16S", copies: 2, type: "rRNA"}
      - name: string
      - copies: unsigned_integer
    split_by: ","
    implicit: {type: "rRNA"}
```

A possible application: different alternative datatypes for an element of the
format may be defined using `one_of` (see below). Combined with `implitic` it
can be e.g. used to specify a format in which a middle element of a
`composed_of` is allowed to be missing:
```YAML
  dict10:
    one_of:       # e.g. "X,+" <-> {name: X, expressed: true, copies: 1}
      - composed_of:
          - name: string
          - expressed:
              accepted_values: {"+": true, "-": false}
        split_by: ","
        implicit {"copies": 1}
      - composed_of:
          - name: string
          - copies: unsigned_integer
          - expressed:
              accepted_values: {"+": true, "-": false}
        split_by: ","
```

#### Special dictionaries representations

As for lists, also for dictionaries, it is possible to decode given strings to
predefined dictionaries, using a decoding mapping, e.g.:
```YAML
datatypes:
  dict9:
    accepted_values:
      "ax": {"a": "x", "b": "y"}
      "ay": {"a", "y", "b": "y"}
      "bx": {"a": "x", "b": "x"}
    empty:  {"a": "z", "b": "z"}
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

### Additional keys

The addional keys depend on the datatype. However, some of the keys
are common for multiple datatypes and are listed here:

`splitted_by`

#### Decoding rules

The value returned by the decoding of a string can be changed, by providing
a mapping instead of the matching value alone:
```YAML
datatypes:
  string7:
    accepted_values:
      - "one": "eins"
      - "two": "zwei"
      - "three": "drei"
```

In the case multiple encoded values represent the same decoded value,
a rule must be added, which explains which of the values shall be
used for encoding that decoded value. This is done using the
`canonical` mapping, for which keys are the encoded values to use
and the values are the values which must be mapped to that particular value:
```YAML
datatypes:
  string8:
    regexes:
      - "[0-9]": "d"
      - "[A-Z]": "c"
    canonical:
      "0": "d"
      "1": "c"
```

If all decoded values all equal, canonical may also just contain a string
(the canonical encoded value):
```YAML
datatypes:
  string9:
    regexes:
      - "[0-9]": "d"
      - "[A-Z]": "d"
    canonical: "0"
```

The decoding rules are not limited to mapping strings to other
strings. Any value which can be represented as JSON
can be used as a decoded value.

```YAML
datatypes:
  string10:
    accepted_values:
      - "s": ""
      - "l": []
      - "d": {}
```

#### Default decoded value

In case an empty string shall be accepted, in alternative
to the strings matching the definition, the `empty` optional
key can be used:
```YAML
datatypes:
  string11:
    constant: {"+": true}
    empty: false
```

The value provided by `empty` has higher priority. Thus also
if e.g. a regular expression matching also an empty string is
provided, the `empty` case is handled as defined. E.g. in the
following case, the empty string results in a decoded value 0:
```YAML
datatypes:
  string12:
    regex: "\d*"
    empty: "0"
```

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

## References

Wherever in the specification a datatype definition can be given (as
a mapping), a reference to another datatype definition can be also given
instead, as a string.

This has the advantage to allow for reusing a definition in different
contexts, e.g. multiple elements of compound datatypes can have the same
definition.

Definitions must be not be given in a particular order. That is,
they can reference to definitions given later in the file, e.g.:
```YAML
datatypes:
  a: {list_of: b, splitted_by: ","}
  b: unsigned_integer
```

References are now allowed to be circular, neither directly or indirectly.
E.g. the following results in an error:
```YAML
datatypes:
  a:
    one_of:
      - constant: "xxx"
      - b
  b: {list_of: c}
  c: a # ERROR!!!
```

If a file is included (see below), then reference can also refer to
included files:
```YAML
include: a.yaml # defines "a"
datatypes:
  b: {list_of: a}
```

It is possible also to write incomplete specifications, with references
to missing definitions. Those specifications are then only valid when included
in other specifications, which defines the missing definitions:
```YAML
# file a.yaml, incomplete, definition of b missing
datatypes:
  a: {list_of: b, splitted_by: ","}

# file b.yaml, includes and completes a.yaml
include: a.yaml
datatypes:
  b: unsigned_integer
```

## Include

## Namespace

## Embedded specifications

Specifications can be embedded in data files.
Specifically, the file may contain the specification in YAML format,
preceding the data itself and separated from it by a YAML document separator
line (`---`), such as in the following example:
```YAML
datatypes:
 default:
   constant: "xxx"
   scope: line
---
xxx
xxx
```

