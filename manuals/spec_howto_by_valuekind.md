# Definitions by kind of represented value

The goal of a specification is to describe each part
of the format, separately, and how to combine them, hierarchically,
to compose the entire format. The smallest components are often
scalar values: strings, numbers, booleans, undefined values.
These are usually combined into sets of values.

The following section
describes how to describe parts of the format, depending on the type
of value they represent.

## An example

When writing the specification for a format, you will need to think
what is the target kind of data for the result of parsing each part of a
format and then read the corresponding section. E.g. the following format:
```
A 1,2,3,4 k:T
B 23,12 y:-1.3;y:1.2;k:F;y:3
```
could consists of a list of lines which have the same structure
of three elements (1st: "A"/"B"; 2nd: "1,2,3,4"/"23/12"; 3rd: "k:T"/"y:-1.3...")
(thus see "Lists" section below).

Each of the lines consisting of three elements, which have distinct
datatypes, depending on their order (thus see section "Dictionaries
represented by elements in fixed order" below).

We will then need to define the three elements of each line. The first element
is the "name", and it should be decoded as a string (thus see section "Strings"
below). The second element of the line is a list of "counts" and is again a
list (section "Lists"); each item the list is an integer (thus
see section "Numberical values" below).

The third element of the line is a set of
key/value pairs (section "Dictionaries by key/value pairs"). The key
`k` is required in each line and there is only an instance of it. It contains
a boolean value `T` for true, or `F` for false (see section
"Booleans and undefined values" below). THe key `y` can be found multiple
times in the line and contains a float (see section "Numberical values").

After referring to the sections below, the resulting specification could be:
```YAML
datatypes:

  line:
    composed_of:
      - name:       one_upcase_letter
      - counts:     counts_list
      - attributes: attributes_table
    splitted_by: " "

  one_upcase_letter:
    regex: "[A-Z]"

  uint_list:
    list_of: unsigned_integer
    splitted_by: ","

  attributes_table:
    named_values:
      y: float
      k: {values: {"T": true, "F": false}}
    required: [k]
    single: [k]
```

## Strings

The following definitions describe components of a format which represent
strings, either unchanged from the textual representation
or modified.

If a component of a format can contain any string,
the predefined `string` datatype can be used for it.

If only one or one of a list of possible values are allowed, then,
respectively, a `constant` or `values` definition can be used:
```YAML
datatypes:
  string1: {constant: "XYZ"}
  string2: {values: ["ABC", "DEF"]}
```

If a string must match a given regular expression, a definition of kind
`regex` or `regexes` (multiple regexes are automatically concatenated)
can be used:
```YAML
datatypes:
  string3: {regex: "[ABC]{1,3}"}
  string4:
    regexes:
    - "[ABC]{1,3}"
    - "[DEF]{5,7}"
```

If the empty string also matches, its value can be provided using `empty` (as
for any kind of definition). This has the highest priority. Thus also if e.g. a
regular expression matching also an empty string is provided, the `empty`
case is handled as defined. E.g. in the following case, the empty string
results in a decoded value 0:
```YAML
datatypes:
  string12:
    regex: "\d*"
    empty: "0"
```

### Validation of a string by datatype definition

In some cases, although a value shall be decoded as string, and not further
parsed into smaller elements, its format is quite complex.

In this case it can be useful to create a definition (e.g. for a compound
datatype, as explained below) and then let TextFormats know that the
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

### Parsing rule: decoded string different from the encoded

By default, string are just encoded as the string itself, i.e. parsing involves
validation, but no modification of the value itself. In some cases a different
string should be present in the textual representation compared to the decoded
value: e.g. one could want to expand an acronym. For this a decoded mapping is
used:

Examples:
```YAML
datatypes:
  string7:
    values:
      - "USA": "United States of America"
      - "UK": "United Kingdom"
```

Furthermore, a default value is sometimes useful for strings when the
element is absent from the encoded representation. For this the
`empty` key is used, e.g.:
```
datatypes:
  string8:
    values:
      - "USA": "United States of America"
      - "UK": "United Kingdom"
    empty: "Worldwide"
```

If multiple encoded values are decoded to the same decoded value (always for
regular expressions), then canonical encoded forms must be specified, so that
the encoder knows which one shall be used. E.g.:
```
datatypes:
  string9:
    regexes:
      - "U(SA?|sa)": "United States of America"
                     # USA, US, Usa are all accepted
      - "U[Kk]": "United Kingdom"
    canonical:
      - "USA": "United States of America"
      - "UK": "United Kingdom"
```

If all decoded values all equal, canonical may also just contain a string
(the canonical encoded value):
```YAML
datatypes:
  string15:
    regexes:
      - "[0-9]": "d"
      - "[A-Z]": "d"
    canonical: "0"
```

## Numerical values

The following definitions describe components of a format which represent
numerical values.

The predefined `integer`, `unsigned_integer` and `float` datatypes
are used for numerical values where every valid value shall be accepted.

If only a single value or a value in a given set of values shall be accepted
a `constant` or, respectively, `values` definition is used:
```YAML
datatypes:
  num1: {constant: 3}
  num2: {values: [1,2,3]}
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

### Specially formatted numbers

In general, there is no special support for numbers formatted unconventially.
That is, they must be validated as strings and the conversion to/from numbers
is then done in the calling code. An exception are cases in which there is
a limited number of values, for which the textual representations
can be simply enumerated:
```YAML
datatypes:
  num7:
    values:
      - "I": 1
      - "II": 2
      - "III": 3
```

## Boolean and undefined values

The following definitions describe components of a format which represent
boolean values and/or undefined values.

In these cases, one or multiple string valid representations exist
for each of the decoded values. These can be provided using
an `values` definition and a mapping. If multiple encodings
are possible, `canonical` representations must be choosen
(always if regexes are used):
```YAML
datatypes:
  boolean1:
    values: ["T": true, "F": false, "NA": null]
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

## Elements with multiple possible types

In some cases an element of a format can be expressed in multiple
different ways. They are defined, as a list under the key `one_of`.

E.g. the following allows to represent an unsigned integer value,
as a number, if it is >= 1, otherwise by the string `*`, to
represent the value 0:
```YAML
datatypes:        # "*" <-> 0
  num8:           # "1" <-> 1
    one_of:
      - unsigned_integer: {min: 1}
      - constant: {"*": 0}
```

Note that the content of `one_of` is a list; the order of the list
defines the order or precedence of the definitions (the first which
applies is used).

In case the decoded value shall contain information about
which "branch" of `one_of` has been used, `wrapped` can be set.
The default "branch names" are not so informative (e.g. `[1]`)
if the branches are defined inline, thus in this case, use
`branch_names` together with `wrapped` to manually set them:

```
datatypes:
  list11:     # *,-1 <-> [{"[2]": null}, {"integer": -1}]
    list_of:
      one_of:
        - integer
        - {constant: {"*": null}}
      wrapped: true
      branch_names: [integer, undefined]
    splitted_by: ","
```

## Lists

The following definitions describe components of a format which represent
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

### Formatting

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

### Validating the number of elements

In some cases there is a minimum and/or maximum or a fixed number elements
of the list. This can be enforced:
```YAML
datatypes:
  list6:     # e.g. 0;-1;32
    list_of: integer
    splitted_by: ";"
    length: 3
  list7:
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
``

### Lists of herogeneous elements

A ``one_of`` definition can be combined with a ``list_of`` definition to implement
lists of elements which have different types, but are not in a particular
order.

That is, the type of the elements is not dependant on the
order, and it is also not annotated as a key or typecode.
Instead, it is the formatting of the element itself which reveals
the type.

For example, the following defines a list containing either
integers or undefined values, denoted by ``*``:
```YAML
datatypes:
  list10:     # 1,-3,*,5,*,-2 <-> [1, -3, null, 5, null, -2]
    list_of:
      one_of:
        - integer
        - {constant: {"*": null}}
    splitted_by: ","
```

### Lists from predefined representations

Using decoding mappings and/or a default decoded value (see below) is it
possible to decode given strings to predefined lists. E.g.
```YAML
datatypes:
  list9:
    values:
      "1a": ["a"]
      "2a": ["a", "a"]
      "3a": ["a", "a", "a"]
    empty: []
```

In case multiple representations of the same value are given,
the `canonical` key must define which one shall be used for encoding:
```YAML
datatypes:
  list10:
    values:
      "a": ["a"]
      "1a": ["a"]
      "2a": ["a", "a"]
      "3a": ["a", "a", "a"]
    empty: []
    canonical: {"1a": ["a"]}
```

## Dictionaries

The following definitions describe components of a format which represent
multiple elements, each potentially with a different data type,
and associated to a name/key which describes them.

The text representation can in some cases explicitely contain the
keys of the single elements. In many cases, however, the semantics
and datatype of the components is defined by their position in the
text, relative to other components of the format.

### Dictionaries represented by elements in fixed order

This section handles dictionaries represented by a text in which
the order of the elements is fixed: the position of an
element in the sequence determines the semantic and datatype.

For this kind of representation, a
`composed_of` definition is used. Under the key, a list is of tuples
is given, each one as name and definition. Note that this is a list
(thus the `-` in YAML) and not a mapping, since the order of the elements
is important:
```YAML
datatypes:
  dict1:
    composed_of:
      - first: unsigned_integer
      - second: float
      - third: {regex: "[A-Za-z0-9]"}
    splitted_by: " "
```

#### Formatting

The `splitted_by`, `separator`,
`prefix` and/or `suffix` keys can be used to specify the formatting
and how to parse the elements. Please refer to the "Formatting" subsection
in the "Lists" sections above.

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

#### Optional elements

Some of the elements can be optional, i.e. sometimes absent from the
sequence of elements. Three cases can be distinguished.

(1) In the first case, the
sequence is splitted by a non-empty separator string; thus an empty
element can be recognized by the presence of this separator. In this
case `empty` keys are used in the elements definitions:
```YAML
datatypes:
  dict3:            # e.g. ;B <-> [0, "B"]
    composed_of:
      - first: {values: [1,2], empty: 0}
      - second: {values: [A,B], empty: C}
    splitted_by: ";"
```

(2) In the second case, the first elements of the sequence may be mandatory,
while the following can be present or not (and are mandatory only
if elements after them in the order are present). In this case, the
`required` key is used:
```YAML
datatypes:
  dict4:            # e.g. 1 <-> [1, "C"]
    composed_of:
      - first: {values: [1,2], empty: 0}
      - second: {values: [A,B], empty: C}
    splitted_by: ";"
    required: 1
```

(3) In the third case, some internal element can be missing, together with its
associated separator. In this case, there must be no ambuiguity, i.e. because
the following element of the sequence has a type that allows it to be
distinguished from the optional element, or because the total number of
elements changes depending on the presence or absence of the optional element.

The solution for these cases is to provide multiple alternative definitions of
the structure (i.e. with and without the optional element)
using a `one_of` definition. An example:
```YAML
datatypes:        # 1,A,2 <-> {a: 1, x: "A", b: 2}
  dict5:          # 1,2   <-> {a: 1, b: 2}
    one_of:
      - composed_of:
          - a: unsigned_integer
          - x: {values: [A, B]}
          - b: unsigned_integer
        splitted_by: ","
      - composed_of:
          - a: unsigned_integer
          - b: unsigned_integer
        splitted_by: ","
```
Note that we might want to add also a default value for `x` in case it is
missing. For this see below the section "Adding implicit dictionary entries".

### Dictionaries represented by key/value pairs

In case a elements are represented in a non-fixed order, the semantic
and datatype of the elements is sometimes given as a key preceding
the value. The set of possible keys is known in advance. In this case
a `named_values` definition is used:
```YAML
datatypes:
  dict6:
    named_values:
      rank: unsigned_integer
      name: string
    splitted_by: ";"
```
The keys and the datatypes of the associated values are given under
the `named_values` key, as a mapping.

Note that an `internal_separator` string can be specified, separating the key
from the value. The default is `:`. The internal separator cannot be empty and
cannot occur in the keys, but it can occur in the values.

Names are by default allowed to present multiple times in the list. For
this reason, the elements values are always given in the decoded value as lists.
In some cases, all or some of names can only be present once. This can
be enforced by listing them under the `single` key:
```YAML
datatypes:
  dict7:
    named_values:
      rank: unsigned_integer
      name: string
    splitted_by: ";"
    single: [rank, name]
```

Also, by default, some names may be absent in the set of elements. If some
of the names must be present, they are listed under the `required` key:
```YAML
datatypes:
  dict8:
    named_values:
      rank: unsigned_integer
      name: string
    splitted_by: ";"
    internal_separator: "="
    required: [name]
```

### Dictionaries represented by name/typecode/value triples

In some cases the values of a set are given
in a non-fixed order, and are each accompanied by a name and typecode,
i.e. as triples value/name/typecode.

Thereby, the name defines the semantic of the value and not all names
(differently from named values) must be defined in advance.  The typecode is
associated to a datatype definition.

For these cases, the `tagged_values` definition
key is used, under which all available datatypes codes and the associated
datatype definitions are given under the `tagged_values` key as a mapping.
```YAML
datatypes:
  dict9:  # e.g. A.i.12;B.f.1.3 <-> {"A": 12, "B": 1.3}
    tagged_values:
      i: integer
      f: float
    tagname: "[A-Z]"
    internal_separator: "."
    splitted_by: ";"
```
The valid names and their formatting is specified using
a regular expression. The internal separator key has a default value `:`
and it must be a non-empty string. It cannot be present in tagnames
and type codes (but can be present in values).

### Dictionaries from predefined representations

Using decoding mappings and/or a default decoded value (see below) is it
possible to decode given strings to predefined dictionaries. E.g.
```YAML
datatypes:
  dict10:
    values:
      "ax": {"a": "x", "b": "y"}
      "ay": {"a", "y", "b": "y"}
      "bx": {"a": "x", "b": "x"}
    empty:  {"a": "z", "b": "z"}
```

In case a data value has multiple textual representations, the
canonical one must be specified, which is then used for encoding:
```YAML
  dict11:
    values:
      "1": {"a": "x", "b": "y"}
      "2": {"a", "x", "b": "y"}
    canonical: {"1": {"a": "x", "b": "y"}}
```

### Adding implicit entries to dictionaries

In some cases, the decoded dictionary shall contain a given constant
key/value pair, which is not explicitely encoded. These are specified
using the `implicit` mapping, which is available for `composed_of`,
`named_values` and `tagged_values` definitions:
```YAML
  dict11:
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
  dict12:
    one_of:       # e.g. "X,+" <-> {name: X, expressed: true, copies: 1}
      - composed_of:
          - name: string
          - expressed:
              values: {"+": true, "-": false}
        split_by: ","
        implicit {"copies": 1}
      - composed_of:
          - name: string
          - copies: unsigned_integer
          - expressed:
              values: {"+": true, "-": false}
        split_by: ","
```
