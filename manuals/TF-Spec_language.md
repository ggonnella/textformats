# TF-Spec: TextFormats specifications syntax

The goal of the TextFormats library is to parse a textual representation
of data and translate it into data (decoding) and vice versa (encoding).
In order for the library to know how to access the data, the user
must describe the format of the textual representation and the rules used for
validating, decoding and encoding the data. This is done by writing a
specification.

Specifications are written using a declarative language named TF-Spec.
The syntax of the language is conceived so to be representable as a
JSON object or a YAML 1.2 mapping: i.e. keywords are given in the form
of mapping keys (as strings) and their arguments are the values associated
with the key (in the form of mappings, sequences/lists or scalars).

Examples in this file are given as YAML 1.2. However the language can
also be written in JSON format, or a mapping with the same content
can be constructed programmatically.

## Sections

As explained above, a specification must be a mapping. The root level
of the mapping contains keys, which define different sections of the
specification.

The following sections are defined:
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

Any other key at root level is currently ignored, but could be in use in future
versions.  A specification must contain at least a `datatypes` and/or an
`include` section to be valid.  The syntax and purpose of each of the sections
is explained in the next sections.

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

## Datatype definitions under 'datatypes'

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

## Reusing definitions in multiple contexts

Since the same definitions can often be used in different contexts
(e.g. multiple components of a compound datatype), it is possible to
use references to definitions (a string, name of the datatype to which
to refer) in all contexts of the specification, where a definition
mapping can be used.

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

### Reusing definitions across specification files

References are useful in order to reduce the need to re-define identical parts
of a format again and again. However, sometimes, the same datatypes are used in
different formats. For example, CIGAR strings are used in SAM files, in GFA
files and other formats.

The definitions to which to refer can also be stored in a file, which is
included in the specification. The path to the files are given under the
specification root, in the entry `include`.  Included files can themselves
include further files: thereby circular dependencies are not allowed.

The content of include describes which specifications to include
and, optionally, which datatypes of those specification to include
(by default: all).

In case all datatypes of a specification file shall be included, a string is
used under `include`, the relative path to the specification file to be
included. If multiple files shall be included, a list is used.
If the specification with the `include` key is stored in a file,
the path is relative to that file. If created programmatically or
read from a pipe, then it is relative to the current working directory.

For example a file `b.yaml` could include `a.yaml` file in the same
directory, and a `c.yaml` file in the parent directory:
```YAML
include: [a.yaml, "../c.yaml"]
datatypes:
  ...
```

The datatypes of included files can be used like locally defined
datatypes: i.e. they can be referred to, in other datatype definitions;
also, they can be passed to the library functions, when the including
specification is used.

```YAML
include: a.yaml # defines "a"
datatypes:
  x: {list_of: a}
```

In case only some of the datatype are included, a mapping is used, where the
key is the relative path to the specification file to be included and the value
is a list of strings, the names of the datatypes of that specification to
include. Also when using a list of files to be included, each element of the
list can be either a string (relative path to a specification file) or a
mapping (key: path; value: datatypes list).  For example:
```YAML
include: [a.yaml: [a,b], "../c.yaml"]
datatypes:
  x: {list_of: a}
```

Including files can redefine any datatype of an included specification.
Thereby it does not matter if the `include` key comes before or after
the `datatypes` key in the specification: in all cases, definitions
of the including file have priority over those of included files.
Here is an example of redefinition of a datatype:
```YAML
include: a.yaml # defines "a" and "b"
datatypes:
  a: {constant: "a"}   # overwrite "a" definition
  x: {list_of: b}      # while "b" is used as defined in the included file
```

Also, it is allowed to include incomplete specifications. These refer, in some
compound datatype and/or alias, to a datatype which is defined in the including
specification. Those specifications are then only valid and usable when
included in other specifications, which define the missing definitions:
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

Since defining a datatype with the same name of an included one would redefine
it, users would have to carefully avoid unwanted redefinitions due to name
clashes. This risk is reduced by using namespaces.

The `namespace` entry under the specification root may be used, with as value a
non-empty identifier (starting with a letter and consisting of letters, numbers
and underscores). The value is used as a prefix (followed by `::`) for all
datatypes of the specification, when it is included in another specification.

E.g.
```YAML
# specification foo.yaml
namespace: "foo"
datatypes:
  y: string

# specification bar.yaml
include: "foo.yaml"
namespace: bar
datatypes:
  x: "foo::y"
```

Referring to datatypes of namespaced specification included in other
namespaced specification leads to multiple prefixes, each ending with
`::`, such as in the case of datatype `w` in the following example.

```YAML
include "bar.yaml"
datatypes:
  w: "bar::foo::y"
```

Included namespace-prefixed datatypes can be redefined,
as any other datatype in the included specification, such as in the
following example:

```YAML
include "bar.yaml"
datatypes:
  bar::foo::y: unsigned_integer
```

Thereby, using a namespace prefix which has not been defined in an imported
file is an error.
```YAML
# no includes
datatypes:
  x::y: string # ERROR
```

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

## Definitions of kind `constant`

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

## Definitions of kind `values`

Definitions with kind-of-definition key `values` are used to
define a datatype, by which a finite (typically small) number
of textual representations are used to express a finite (typically small)
number of data values.

The content of the `values` key is a list of the possible values.
Each element of the list follows the same conventions as described above
for `constant`, i.e. it can be:

| element value | text representation | decoded value |
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
    values:
      - "1": "A"
      - 1: "B"
```

Here are examples of `values` definitions:
```YAML
datatypes:
  av1: {values: ["a", "b", "c"]}
  av2: {values: ["a", "1": "b"], empty: "c"}
  av3: {values: [1, 2, 3]}
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

## Definitions of kind `float`

Definitions of kind `float` are used for elements which have a numeric
floating point value. The text representation can be any of the
conventional representations for floating points, i.e. including E notation,
positive and negative numbers.

The value of the `float` key is a mapping; the validity range
can be specified, using the optional keys `min` and `max` in this mapping.
Additionally it can be specified if the intervals are open or closed
(i.e. if the extreme values shall be accepted or not), using the
keys `min_excluded` and `max_excluded`. The default is to accept
the interval extreme values.

The mapping under `float` may be as well empty, if no validity range is
specified. If no other option of the definition mapping besides `integer` is
used, the definition mapping is `{float: {}}`, which is equivalent to the predefined
datatype `float` (but the latter is skipping range checks, thus may be faster
in the implementation).

If an empty string shall be accepted, the key `empty` and a data value, to be
used in that case, shall be added to the definition.

Here are examples of `float` definitions:
```YAML
datatypes:
 f1: float # predefined, equivalent to f2
 f2: {float: {}}
 f3: {float: {}, empty: 0}
 f4: {float: {min: -10.0
 f5: {float: {max: 100.0
 f6: {float: {min: -10.0, max: 100.0}}
 f7: {float: {min: -10.0, min_excluded: true}}
```
## Definitions of kind `one_of`

Definitions of kind `one_of` are used for elements for which multiple
type of values are possible. That is instead of a single definition,
for the element, a list of definitions is given, under the `one_of` key.

The branches of a `one_of` definition must be at least two.  The branch
definitions can be given directly (definition mapping) or a reference can be
used, i.e. the name of a pre-defined or user defined definition can be input
(string). The branch definitions can be of any kind, i.e. scalar, compound of
even `one_of` definitions.

Here are examples of `one_of` definitions:
```YAML
datatypes:
  o1: {one_of: [integer, float]}
  o2:
    one_of:
      - float: {min: 0.0, max: 1.0}
      - regex: "[A-Z]{3}"
```

The value of the decoded data of the `one_of` element is, by default, the
decoded value of the first definition for which the textual representation is
valid (first in the order they are given in the list under `one_of`).  Also, by
default, when encoding data with a `one_of` datatype, the first of the
definitions given under `one_of` (in the order they are given) for which the
data is valid is applied.

For example, when using the `o1` datatype, the decoded value of `1` would be
the integer 1, although the floating point number 1.0 could have the
same representation: this is the branch`integer` comes before `float`
in the definitions list under ``one_of``.

### Wrapped ``one_of`` definitions

In some cases, however, it is useful to know which of the definitions of the
`one_of` was applied to decode the textual representation.  In this case the
`wrapped: true` option can be added to the definition mapping. For each of the
"branches" (definitions listed under `one_of`) a name is assigned. The decoded
value is then a single-entry mapping, where the key is the name of the first
branch for which the textual representation is valid and the value is the
decoded value obtained by applying the branch definition.

The default names used for `wrapped` are computed as follow. If a branch
definition is given as a reference, then the name of the target of the reference
is used (i.e. the string entered). If a branch definition is given as a mapping,
the name is the ordinal number of the branch, enclosed in square brackets
(starting from `[1]`). For example, in the definitions given below, the branch
names would be: `integer` and `string` for `ow1`; `float` and `[2]` for `ow2`.
In place of the default names, user-defined branch names can be
entered in the definition as a list of string, under the `branch_names` key,
such as in the example `ow3`.

Examples of `one_of` definitions using `wrapped` are given here:
```YAML
datatypes:
  ow1: {one_of: {integer, float}, wrapped: true}
  ow2:
    one_of:
      - float
      - regex: "[A-Z]{3}"
    wrapped: true
  ow3:
    one_of:
      - float
      - regex: "[A-Z]{3}"
    wrapped: true
    branch_names: [float_score, letters_score]
```

Here are examples of applying the above definitions for decoding a textual
representation:

| Definition | Text repr. | Data value (JSON)           |
| ---        | ---        | ---                         |
| ``o1``     | ``1``      | ``1``                       |
| ``ow1``    | ``1``      | ``{"unsigned_integer": 1}`` |
| ``o2``     | ``ACZ``    | ``ACZ``                     |
| ``ow2``    | ``ACZ``    | ``{"[2]": "ACZ"}``          |
| ``ow3``    | ``ACZ``    | ``{"letters_score": "ACZ"}  |

## Definitions of kind `list_of`

Definitions of kind `list_of` are used for compound elements which consist of
ordered sets of instances of sub-elements, for which the type does not depend
on the ordinal position in the set, i.e. all sets elements have the same
datatype definition (or any of a list of given datatype definitions, branches
of a `one_of` definition). The datatype for the list elements is given under
the `list_of` key, either as a definition mapping, or as a reference to another
datatype.  Any kind of of element definition can be used (including lists and
other compound datatypes, although in this case the definition must carefully
avoid ambuiguitites, e.g.  using different separator strings).

The decoded data value of a `list_of` definition is a sequence (Nim, YAML),
list (Python), JSON array (JSON, C/C++), except if the `as_string` option is
set (see section "Validation-only compound definitions"). By default,
the list must contain at least one element and has no limit in the number of
elements.  Validation rules can be used to set the valid length of the list,
either as a constant (key `length`) or minimum (key `min_length`) and/or
maximum (key `max_length`) number of elements. Empty lists are supported, i.e.
the `min_length` can be set to the value 0.

If in the textual representation, the elements of the list are separated
by a constant string, this can be specified in the definition. If the separator
string is never contained in the elements (not even escaped), it is given
under the key `splitted_by`; otherwise it is given under the key `separator`.
By default no separator string is used. For more details about the use
of separators, see the section "Formatting options for compound definitions"
below.

Examples of `list_of` definitions are given below:
```YAML
datatypes:
  l1:
    list_of: unsigned_integer
    splitted_by: ";"
  l2:
    list_of: {regex: "[^_][A-Z_][^_]"}
    separator: "_"
  l3:
    list_of: {regex: [0-9]}
    length: 3
```

## Definitions of kind `composed_of`

Definitions of kind `composed_of` are used for compound elements which consist
of ordered sets of instances of sub-elements, for which the type depends on the
ordinal position in the set, i.e. each element has a possibly different
datatype definition.  The name and the datatype of each element is given as a
list of one-entry mappings (name: datatype) under the `composed_of` key.
Thereby the datatype is given either as a definition mapping, or as a reference
to another datatype.  Any kind of of element definition can be used (including
`composed_of` and other compound datatypes, although in this case the
definition must carefully avoid ambuiguitites, e.g. using different separator
strings).

The decoded data value of a `composed_of` definition is a table (Nim), mapping
(YAML), dict (Python), JSON object (JSON, C/C++), except if the `as_string`
option is set (see section "Validation-only compound definitions").

By default, the mapping must contain all elements. However it is possible to
make the last elements optional, by setting `required` to the number of
elements which must at least be present (such as in `cof1` below).  When using
`required` "holes" are not allowed; i.e. if an optional element is present,
all elements before it must also be present (this is necessary, since element
name and type are determined by their ordinal position). If a middle element
can be missing, and the different values be reconignized anyway, definitions of
the elements allowing for empty sequences can be used (such as in `cof2`
below). In other cases, e.g. if the separator is missing along with the
element, multiple `composed_of` definitions (with and without the said middle
element) can be combined using a `one_of` definition (such as in `cof3` below).

If in the textual representation, the elements of the list are separated by a
constant string, this can be specified in the definition. If the separator
string is never contained in the elements (not even escaped), it is given under
the key `splitted_by`; otherwise it is given under the key `separator`.  By
default no separator string is used.  If different separators are used for
different elements, they can be defined as `constant` elements and
`hide_constants: true` (which hides all constants from the decoded data) can be
used, such as in `cof2` below.  For more details about the use of separators,
see the section "Formatting options for compound definitions" below.

```YAML
datatypes:
  cof1:
    composed_of:
      - x: integer
      - y: integer
      - z: integer
    splitted_by: ","
    required: 2
  cof2:
    composed_of:
      - node1: {float: {min: 0.0, max: 1.0}}
      - sep1: {constant: "-"}
      - relation: {values: [A, B, C], empty: X}
      - sep2: {constant: "->"}
      - node2: {unsigned_integer: {min: 0, max: 100}}
    hide_constants: true
    prefix: "("
    suffix: ")"
  cof3:
    one_of:
      - composed_of:
          - node1: integer
          - relation: {values: [A, B, C]}
          - node2: integer
        splitted_by: ":"
        prefix: "["
        suffix: "]"
      - composed_of:
          - node1: integer
          - node2: integer
        splitted_by: ":"
        prefix: "["
        suffix: "]"
        implicit: {relation: "X"}
```

The following table gives examples of using the three definitions above:

| Datatype | Text repr. | Data value (JSON)           |
| ---      | ---        | ---                         |
| `cof1`   | `-1,2,4`   | `{"x": -1, "y": 2, "z": 4}` |
| `cof1`   | `2,4`      | `{"x": 2, "y": 4}`          |
| `cof2`   | `(0.232-A->23)` | `{"node1": 0.232, "relation": "A", "node2": 23}` |
| `cof2`   | `(0.232-->23)`  | `{"node1": 0.232, "relation": "X", "node2": 23}` |
| `cof3`   | `1:B:-3` | `{"node1": 1 , "relation": "B", "node2": -3}` |
| `cof3`   | `1:-3`   | `{"node1": 1 , "relation": "X", "node2": -3}` |

## Definitions of kind `named_values`

Definitions of kind `named_values` are used for compound elements which of sets
of instances of sub-elements, each associated to a name (from a set of
predefined names), for which the type depends on the name. The datatype
associated with each of the names is given as a mapping (name: datatype) under
the `named_values` key.  Thereby the datatype is given either as a definition
mapping, or as a reference to another datatype.  Any kind of of element
definition can be used (including `named_values` and other compound datatypes,
although in this case the definition must carefully avoid ambuiguitites, e.g.
using different separator strings).

The decoded data value of a `named_values` definition is a table (Nim), mapping
(YAML), dict (Python), JSON object (JSON, C/C++), except if the `as_string`
option is set (see section "Validation-only compound definitions").
The mapping contains an entry for each of the names present at least once in
the textual representation.

By default, all names may be absent from the set. Names of elements which must
be present at least once can be listed as value of the optional key `required`.
By default, for each name present in the textual representation, the value of
the decoded data entry is a list, containing the possibly multiple values
of the elements with that name. Names of elements which can only be present
once can be listed as value of the optional key `single`.
In case a name is listed under `single`, the value of the entry for the name
(if this is present in the textual representation) is the decoded value
of the element value, and not a list, as it would be if the name is not
in `single`.

For `named_values` datatypes, the name and the value are splitted by a
non-empty string. The default value is `:`, a different value can be given in
the definition mapping under the key `internal_separator`.  The internal separator
must be different from the elements separator given under `splitted_by` and the
two strings shall not contain each other. The internal separator cannot be
contained in the element names, because it is used to split the name from the
rest of the text. However, the textual representations of the element values
can contain the internal separator. The elements separator cannot be present in
both element names and values.

Examples of `named_values` definitions are given here:
```YAML
datatypes:
  nv1:
   named_values:
     score: float
     count: unsigned_integer
     name: {regex: "[A-Za-z]+"}
   splitted_by: "  "
  nv2:
   named_values:
     score: float
     count: unsigned_integer
     name: {regex: "[A-Za-z]+"}
   splitted_by: "  "
   internal_separator: "="
   required: [name, score]
   single: [name]
```

Example of usage of the definitions above are given in the following table:

| Datatype | Text repr.                       | Data value (JSON)                              |
| ---      | ---                              | ---                                            |
| `nv1`    | `count:12`                       | `{"count": [12]}`                              |
| `nv1`    | `score:1.0  score:2.0  count:12` | `{"score": [1.0, 2.0], "count": [12]}`         |
| `nv2`    | `name=A  score=1.0`              | `{"score": [1.0], "name": "A"}`                |
| `nv2`    | `name=A  score=1.0  count=12`    | `{"name": "A", "score": [1.0], "count": [12]}` |

## Definitions of kind `tagged_values`

Definitions of kind `tagged_values` are used for compound elements which of
sets of instances of sub-elements, each associated to a tagname and a typecode
(from a set of predefined typecodes), for which the type depends on the
typecode. The datatype associated with each of the typecodes is given as a
mapping (typecode: datatype) under the `tagged_values` key.  Thereby the
datatype is given either as a definition mapping, or as a reference to another
datatype.  Any kind of of element definition can be used (including
`tagged_values` and other compound datatypes, although in this case the
definition must carefully avoid ambuiguitites, e.g.  using different separator
strings).

The decoded data value of a `tagged_values` definition is a table (Nim),
mapping (YAML), dict (Python), JSON object (JSON, C/C++), except if the
`as_string` option is set (see section "Validation-only compound definitions").
The mapping contains an entry for each of the tagnames present in the textual
representation. Multiple instances of the same tagname are not allowed (as by
the current implementation). The value of the entry for a tagname is a mapping
with two entries, `type` and `value`. The value of `type` is the typecode, as
string. The value of `value` is the decoded data value of the tag value,
according to the type definition given for the tag typecode.

Predefined tags are tagnames for which a given type must be used, if they
are present. They can be specified using the `predefined` key. This contains
a mapping with entries tagname:typecode for each of the predefined tags.
The `tagnames` key allows to specify a regular expression for the validation
of the tagnames. The default value is `[A-Za-z_][0-9A-Za-z_]*`.
Predefined tagnames do not have to match it. If it is set to an empty
string, no other tagnames except the predefined ones are allowed.

For `tagged_values` datatypes, the tagname, typecode and the value are splitted
by a non-empty string. The default value is `:`. A different string can be
specified in the definition mapping under the key `internal_separator`. The
internal separator must be different from the elements separator given under
`splitted_by` and the two strings shall not contain each other. The internal
separator cannot be contained in the tagnames and in the typecodes, because it
is used to split them from the rest of the text. However, the textual
representations of the tag values can contain the internal separator. The
elements separator cannot be present in tagnames, typecodes or values.

The following are examples of `tagged_values` definitions:
```YAML
datatypes:
  t1:
   tagged_values:
     f: float
     u: unsigned_integer
     n: {regex: "[A-Za-z]+"}
   splitted_by: " "
  t2:
   tagged_values:
     s: float
     u: unsigned_integer
     n: {regex: "[A-Za-z]+"}
   splitted_by: " "
   internal_separator: "="
   tagnames: ""
   predefined: {"AB": "s", "CD": "u", "XX": "n"}
```

Example of usage of the definitions above are given in the following table:

| Datatype | Text repr.               | Data value (JSON)                                                    |
| ---      | ---                      | ---                                                                  |
| `t1`    | `count:u:12`              | `{"count":{"type":"u","value":12}}`                                  |
| `t1`    | `score:f:1.0 count:u:12`  | `{"score":{"type":"f","value":1.0},"count":{"type":"u","value":12}}` |
| `t2`    | `XX=n=A AB=s=1.0`         | `{"AB":{"type":"s","value":1.0},"XX":{"type":"n","value":"A"}}`      |

## Formatting options for compound definitions

In the textual representation of a compound datatype, the textual
representations of the elements are either just concatenated to each other, or
separated by a constant string. Furthermore, they can be preceded and followed
by constant strings, such as opening and closing brackets.

### Separators for `list_of` and `composed_of` definitions

For `list_of` and `composed_of` definitions, two kind of options can be used to
specify a separator string, if necessary.  If the separator string is never
contained in the text representation of the elements (not even in an escaped
form), the `splitted_by` key is used.  In this case, the parser directly uses
the separator string in some cases for splitting the textual representation.
In the case the separator string can be present in the elements, the
`separator` key must be used instead.

If no separator is present, the elements must be separable by other means, i.e.
by the formatting of the elements themselves. E.g. `-10-2-332` could be a valid
representation of a list of negative integers, without the need of a separator,
since the `-` sign allows to parse the list correctly. Similarly `025` could be
a valid representation of a list of single-digit numbers, since the length of
the elements allow to parse them. However, for a list of three unsigned
integers [10, 2, 332], the representation `102332` would not be viable, since
there is no way to distinguish it e.g.  from [102, 33, 2]; thus in this case a
separator is needed.

### Heterogeneous separators in `composed_of` definitions

The separator between two elements of lists must always be the same.  For
`composed_of` definitions, however, there is the possibility to use different
separators at different positions, e.g. between the first and second element
than between the second and the third. For this, the `splitted_by` and
`separator` options are not used. Instead, the separator are specificy under
the `composed_of` key, alongside the other elements, as `constant` definitions
(any name can be given to them). The `hide_constant: true` option is then
added to the definition mapping; the data value will then not contain the
constant separator values.

The following is an example, for representing triples of unsigned integers
separated by `:` between the first two elements and `/` between the second
and the third:
```YAML
datatypes:
  xyz:
    composed_of:
      - x: unsigned_integer
      - xy_sep: {constant: ":"}
      - y: unsigned_integer
      - yz_sep: {constant: "/"}
      - z: unsigned_integer
    hide_constants: true
```

For example the string `1:20/0` would be parsed using the definition `xyz`
as `{"x": 1, "y": 20, "z": 0}`.

### Separators for `named_values` and `tagged_values` definitions

In the current implementation, `named_values` and `tagged_values` only support
the `splitted_by` key and the key is required for these kind of definitions.
I.e. a non-empty string must be present between the elements, which is never
found in the textual representation of the elements themselves.

Besides the elements separator, the `named_values` and `tagged_values`
definitions, must include a key for specify the separator used for splitting
the components of the elements (`internal_separator`).  More details are given
in the two sections describing these kinds of definitions.

### Prefix and suffix

The textual representations of the elements of a compound datatype are
sometimes preceded and/or followed by constant strings. E.g. often a list of
elements is enclosed in brackets. It is therefore possible to specify which
strings to use, under the keys `prefix` and `suffix` of the datatype definition.
By default, no prefix and suffix are used.

## Validation-only compound definitions

If the option `as_string: true` is added to the definition mapping, the decoded
data value of the definition is the textual representation of the string.
I.e. the definition is then used for parsing and validation, but then the
unparsed string is used as decoded value.

This option can be added to any definition. In particular, it can be used
instead of complex regular expressions for defining compound elements which
must be left as strings when decoded.

```YAML
  ls1:
    list_of:
      one_of:
      - {regex: [0-9]}
      - composed_of:
        - x: {regex: "[A-Za-z]+"}
        - y: {regex: "[A-Za-z]+"}
        splitted_by: ","
    min_length: 0
    max_length: 10
    splitted_by: ";"
    as_string: true
```

For example the above definition `ls1` is equal to a
`regex` definition, with the regular expression
`(([0-9]|[A-Za-z]+,[A-Za-z]+)(;([0-9]|[A-Za-z]+,[A-Za-z]+)){0,9})?`.

An example match would be the string `0;1;ab,c;11267;D,efG;12`. Without
`as_string` it would be parsed to `[0, 1, {"x": "ab", "y": "c"},
11267, {"x": "D", "y": "efG"}, 12]`. However, using `as_string`, the
element is validated by the regular expression, but the decoded value
is the string itself.

## File parsing

Since this is a common task, specialized functions of the TextFormats library
are used to parse the entire data contained in a file.

Thereby, a datatype definition must describe the structure of the file.
The key `scope` can be added to any datatype definition, which is used
for this purpose. Its value exactly defines which part of the file
is described by the datatype definition.

The following list summarizes the possible values of `scope`:

`line`
: each line of the file is parsed independently from the rest of the file
and has this datatype definition
`unit`
: the file consists of parts, each of a fixed number of lines; these
are called "units" in TextFormats; each unit of the file is parsed
independently from the rest of file, and has this datatype definition
`section`
: the file consists of parts, each having a given structure, which allows
to recognize their limits, but no fixed number of lines; these are called
"sections" in TextFormats; each section of the file is parsed
independently from the rest of file, and has this datatype definition
`file`
: the datatype definition describes the structure of the entire file

If `unit` is used, the number of lines must be specified, using the
key `n_lines` (unsigned integer value, > 1).

As a convention, when a specification describes a file format, an alias named
`default` shall be defined, referring to the datatype definition used to
parsing a file (which, in turn, shall have a `scope` key). The CLI tools use
`default` as default datatype name; thus when using it for decoding, the user
is not required to use any datatype name option.

Here are examples of definitions for file parsing:
```YAML
include: foo.yaml
datatypes:
  default: file
  line:
    one_of:
      - foo:header_line
      - foo:content_line
    scope: line
    wrapped: true
    branch_names: ["header", "content"]
  unit:
    composed_of:
      - line1: foo:unit_line_1
      - line2: foo:unit_line_2
    splitted_by: "\n"
    scope: unit
    n_lines: 2
  section:
    list_of: unsigned_integer
    splitted_by: "\n"
    suffix: "\n---\n"
    scope: section
  file:
    composed_of:
      - section1:
          list_of: line
      - sep1: {constant: "==="}
      - section2:
          list_of: unit
      - sep2: {constant: "+++"}
      - section3: section
    required: 2
    splitted_by: "\n"
    scope: file
```

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

