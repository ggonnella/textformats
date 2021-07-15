# Format specifications tutorial

The TextFormats library is based on "Specifications", i.e. descriptions
of a format for textual representation of data.

The specification is organized as a set of "datatypes",
each with an own name, which represent single elements of the data in the
format. They are combined in several ways to represent the entire format.

While parsing a format, the input textual representation is always
a string. However, the result of parsing is data, which is either of
a scalar type (such as strings, integers, floats, booleans, null/undefined)
or a compound value (such as lists or dictionaries).

The goal of the format specification is to explain how to:
- extract single parts of the format using compound datatypes
(which define how to extract values as compound values)
- extract the single elements of the compound datatypes
into appropriate scalar values
- validate compound and scalar values, based on required
properties

## Structure of a TextFormats specification

Specifications are written in YAML or JSON format. They consist of a
mapping (dictionary), where the definitions of the datatypes are written
under the key "datatypes". Some more keys can be present in the dictionary
("namespace", "include", "testdata") and are mentioned later.

The "datatype" entry is itself a mapping, where the keys are the
names of the datatype (they must be identifiers, starting with a letter
and consisting of letters, digits and underscores) and the values are the
definitions of the datatypes. E.g. the following structure is used for
defining three datatypes, called `a`, `b` and `c`:
```YAML
datatypes:
  a: ...
  b: ...
  c: ...
```

Each of the values (up here represented by `...`) is either:
- a mapping, giving a datatype definition, contain a definition key, as well as
further optional and/or required keys
- or a string, the name of another datatype, representing a reference to it.

```YAML
datatypes:
  a: { .... } # definition
  b: a        # reference, i.e. "b" is an alias of "a"
```

## Writing a TextFormats specification: practical guide

Assuming a file format already exists, it is necessary to know (either from
examples or from a formal specification document) which are the parts of the
format, and which kind of values are contained in each part.

The goal is to transform (back and forth) the textual representation
into data, that is scalar values (strings, numbers, booleans, undefined),
often combined into compound structures (sequences/lists/arrays,
mappings/dictionaries/tables/structs; similar abstract concepts for
compound data representation have different kind of implementations
in YAML, JSON, Nim, Python, C etc.).

In the next sections of the tutorial, for each of the abovementioned
kind of values, it is explained how to define a textual representation
in a Texformats specification file (the examples are written in YAML),
including rules for describing the formatting, for validating the
content and for tuning the decoded representation.

### An example

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
key/value pairs (section "Dictionaries represented by key/value pairs"). The key
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
      k: {accepted_values: {"T": true, "F": false}}
    required: [k]
    single: [k]
```

## Strings

The following definitions handle values which shall be decoded as
either unchanged or modified strings.

The predefined `string` datatype can be used, if any string is accepted.

If only one or one of a list of possible values are allowed, then,
respectively, a `constant` or `accepted_values` definition can be used:
```YAML
datatypes:
  string1: {constant: "XYZ"}
  string2: {accepted_values: ["ABC", "DEF"]}
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

### Modified decoded strings

By default, string are just encoded as the string itself, i.e. parsing involves
validation, but no modification of the value itself. In some cases a different
string should be present in the textual representation compared to the decoded
value: e.g. one could want to expand an acronym. For this a decoded mapping is
used:

Examples:
```YAML
datatypes:
  string7:
    accepted_values:
      - "USA": "United States of America"
      - "UK": "United Kingdom"
```

Furthermore, a default value is sometimes useful for strings when the
element is absent from the encoded representation. For this the
`empty` key is used, e.g.:
```
datatypes:
  string8:
    accepted_values:
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

Decoding mappings and default values are not limited to strings. See below the
section `Defining decoding rules`.

## Numerical values

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

### Specially formatted numbers

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

## Boolean and undefined values

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

## Lists: multiple items of one type

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
```

## Lists from predefined representations

Using decoding mappings and/or a default decoded value (see below) is it
possible to decode given strings to predefined lists. E.g.
```YAML
datatypes:
  list9:
    accepted_values:
      "1a": ["a"]
      "2a": ["a", "a"]
      "3a": ["a", "a", "a"]
    empty: []
```

## Dictionaries represented by elements in fixed order

This section handles sequences of elements, each one (possibly) with its own
type. The order of the elements is fixed: the position of an
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

### Formatting

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

### Optional elements

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
      - first: {accepted_values: [1,2], empty: 0}
      - second: {accepted_values: [A,B], empty: C}
    splitted_by: ";"
```

(2) In the second case, the first elements of the sequence may be mandatory,
while the following can be present or not (and are mandatory only
if elements after them in the order are present). In this case, the
`n_required` key is used:
```YAML
datatypes:
  dict4:            # e.g. 1 <-> [1, "C"]
    composed_of:
      - first: {accepted_values: [1,2], empty: 0}
      - second: {accepted_values: [A,B], empty: C}
    splitted_by: ";"
    n_required: 1
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
          - x: {accepted_values: [A, B]}
          - b: unsigned_integer
        splitted_by: ","
      - composed_of:
          - a: unsigned_integer
          - b: unsigned_integer
        splitted_by: ","
```
Note that we might want to add also a default value for `x` in case it is
missing. For this see below the section "Adding implicit dictionary entries".

## Dictionaries represented by key/value pairs

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

## Dictionaries represented by name/typecode/value triples

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

## Dictionaries from predefined representations

Using decoding mappings and/or a default decoded value (see below) is it
possible to decode given strings to predefined dictionaries. E.g.
```YAML
datatypes:
  dict10:
    accepted_values:
      "ax": {"a": "x", "b": "y"}
      "ay": {"a", "y", "b": "y"}
      "bx": {"a": "x", "b": "x"}
    empty:  {"a": "z", "b": "z"}
```

## Elements with multiple possible types

In some cases an element of a format can be expressed in multiple
different ways. Thus, it is possible to define the different possible
sub-formats separately. They are defined, in the order in which they
shall be checked, as a list under the key `one_of`.

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

### Lists of herogeneous elements

A `one_of` definition can be combined with a `list_of` definition to implement
lists of elements which have different types, but are not in a particular
order.

That is, the type of the elements is not dependant on the
order, and it is also not annotated as a key or typecode.
Instead, it is the formatting of the element itself which reveals
the type.

For example, the following defines a list containing either
integers or undefined values, denoted by `*`:
```
datatypes:
  list10:     # 1,-3,*,5,*,-2 <-> [1, -3, null, 5, null, -2]
    list_of:
      one_of:
        - integer
        - {constant: {"*": null}}
    splitted_by: ","
```

### Branch names

In some cases, it is interesting to know, besides the value, which
of the possible formats has been used for decoding (or shall be used
for encoding). If the `wrapped` boolean is set to true,
the decoded value is a dictionary, with a single entry, whose key
is the "branch name" and the value is the decoded value:
```
datatypes:
  list11:     # *,-1 <-> [{"[2]": null}, {"integer": -1}]
    list_of:
      one_of:
        - integer
        - {constant: {"*": null}}
      wrapped: true
    splitted_by: ","
```

The branch name is assigned automatically. In case a branch definition
is a reference (see below), the reference name is used (e.g. "integer"
in the previous example). Otherwise
the ordinal number of the branch in the list of branches is used,
enclosed in square brackets (e.g. "[2]" in the previous example).
However, it is possible to specify own meaningful names using a list
under ``branch_names``:
```
datatypes:      # 1  <-> {"I": 1}
  dict11:       # 11 <-> {"F": 10.0}
    one_of:
      - {integer: {max: 9}}
      - {float: {min: 10}}
    wrapped: true
    branch_names: [I, F]
```

## Defining decoding rules

### Default decoded value

In case an empty string shall be accepted, in alternative
to the strings matching the definition, the `empty` optional
key can be used:
```YAML
datatypes:
  string11:
    constant: {"+": true}
    empty: false
```

The value provided by `empty` has the highest priority. Thus also
if e.g. a regular expression matching also an empty string is
provided, the `empty` case is handled as defined. E.g. in the
following case, the empty string results in a decoded value 0:
```YAML
datatypes:
  string12:
    regex: "\d*"
    empty: "0"
```

### Mapping textual representations to decoded values

The value returned by the decoding of a string can be changed, by providing
a mapping instead of the matching value alone:
```YAML
datatypes:
  string13:
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
  string14:
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
  string15:
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
  string16:
    accepted_values:
      - "s": ""
      - "l": []
      - "d": {}
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

## Reusing definitions

### References to other datatypes

Datatype definitions, in form of mappings, are given in the specification
under the `datatypes` key, or as element of the compound datatype
definitions (`list_of`, `composed_of`, `named_values`, `tagged_values`)
or in lists of alternatives (`one_of`).

As seen in multiple examples before, instead of a definition mapping, one
can also enter a string, the name of a predefined datatype (`string`, `integer`,
`unsigned_integer`, `float`, `json`). Similarly, a name of any other
datatype defined in the specification can be used.

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

## Reusing definitions across specification files

References are useful in order to reduce the need to re-define identical
parts of a format again and again. However, sometimes, the same datatypes
are used in different formats. For example, CIGAR strings are used in
SAM files, in GFA files and other formats.

For this reason, it is possible to modularize specifications, i.e. to define the
common datatypes in separate specifications which are then imported.
For this purpose the key `include` is used. It is a key of the root
level mapping of the specification (i.e. the same level as the key `datatypes`).
The value of `include` is a filename (string) or a list of filenames (list of
strings). The filenames are expressed as relative to the path of the
file in which they are included.

For example a file `b.yaml` could include `a.yaml` file in the same
directory, and a `c.yaml` file in the parent directory:
```YAML
include: [a.yaml, "../c.yaml"]
datatypes:
  ...
```

References can then be used to any datatype in the included files:
```YAML
include: a.yaml # defines "a"
datatypes:
  x: {list_of: a}
```

In some cases, only some of the datatypes defined by another specification
shall be imported. In this case a mapping of a filename to a list of datatype
names is used:
```YAML
include: [a.yaml: [a,b], "../c.yaml"]
datatypes:
  x: {list_of: a}
```

It is also possible to re-define some of the datatypes defined in
the included files:
```YAML
include: a.yaml # defines "a" and "b"
datatypes:
  a: {constant: "a"}   # overwrite "a" definition
  x: {list_of: b}      # while "b" is used as defined in the included file
```

It is possible also to write incomplete specifications, with references to
missing definitions. Those specifications are then only valid and can only be
used when included in other specifications, which defines the missing
definitions:
```YAML
# file a.yaml, incomplete, definition of b missing
datatypes:
  a: {list_of: b, splitted_by: ","}

# file b.yaml, includes and completes a.yaml
include: a.yaml
datatypes:
  b: unsigned_integer
```

### Namespaces

TODO: explain `namespace` and make examples (also with sub-namespaces)

## Decoding files

### Embedded specifications

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

When creating the specification object, or using the file as specification
in a command line tool, there are no special parameters to set,
since the first YAML document in the file contains the specification, and this
is the only one read by the specification parser functions. Thus the file
is simply used as a normal specification.

However, if the data in the file shall be decoded, using the provided file
decoding functions or the command line tools, TextFormats must know that
it should start to decode after the end of the first YAML document.
Thus, in such cases, an `embedded` boolean parameter/setting is present,
which must be set, for the decoder to work correctly.

### Scope of the definition

TODO: explain
`scope`, the different scopes and
`n_lines`
