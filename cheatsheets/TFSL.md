# Root level keys

|                                 |                                   |
| ------------------------------- | --------------------------------- |
Definitions of datatypes          | `datatypes`
Include other specification       | `include`
Prefix to use when included       | `namespace`
Examples / Tests                  | `testdata`

# Include
|                                 |                                   |
| ------------------------------- | --------------------------------- |
Include single file | `include: a.yaml`
Include multiple files | `include [a.yaml, b.yaml]`
Include only selected datatypes | `include: {a.yaml: [a, b]}` <br/> `include: [a.yaml: [a, b], b.yaml: [c, d]]`
Specifying namespace if file is include | `namespace: foo`
Use datatype of included file with namespace | `foo::bar`
Refer to file included in included, namespaced | `x::y::z`

# Predefined datatypes

|                                 |                                   |
| ------------------------------- | --------------------------------- |
`integer` | any signed integer (`+` sign is optional)
`unsigned_integer` | any unsigned integer
`float` | any floating point number
`string` | any string
`json` | inline JSON (i.e. without newlines)

# Datatype definition kinds (definition-kind key)

|                                 |                                   |
| ------------------------------- | --------------------------------- |
`constant` | only one possible invariant value
`values`   | value is one of a set of possible values
`regex`    | a match of the provided regular expression
`regexes`  | a match of one of the provided regular expressions
`integer`  | integer, optionally validated by a given range
`unsigned_integer` | unsigned integer, optionally validated by a given range
`float` | floating point value, optionally validated by a given range
`list_of` | ordered set; values datatypes and semantics do not depend on their position
`composed_of` | ordered set; values datatype and semantic depend on their position
`labeled_list` | key/value pairs set; datatype and semantic depend on the key
`tagged_list` | tagname/typecode/value triples set; semantic depends on tagname, datatype on typecode
`one_of` | different formats possible, described as separate definitions

# Other keys (non definition-kind keys)

## Formatting of the text representation

| Key | Definition kinds | Value type | Default | Purpose |
| --- | ---              | ---        | ---     | --- |
| `prefix` | `list_of`, `composed_of`, `labeled_list`, `tagged_list` | string | (empty) | constant string preceding the set of elements |
| `suffix` | `list_of`, `composed_of`, `labeled_list`, `tagged_list` | string | (empty) | constant string following the set of elements |
| `splitted_by` | `list_of`, `composed_of`, `labeled_list`, `tagged_list` | string | (empty) | constant string between elements, never found in them (1) |
| `separator` | `list_of`, `composed_of` | string | (empty) | constant string between elements, possibly also found in them |
| `internal_separator` | `tagged_list`, `labeled_list` | string | `:` | constant string between componentes of each element |
| `canonical` | `regex` | string | undefined | string representation to be used for encoding |
| `canonical` | `regexes`, `values` | mapping | undefined | string representations to be used for encoding |

Notes:
(1) with the possible exception of the last element of `composed_of` elements

## Validation of the represented data

| Key        | Kind           | Value type       | Default | Purpose |
| ---        | ---            | ---              | ---       | --- |
`min_length` | `list_of`      | unsigned integer | 1         | min number of elements |
`max_length` | `list_of`      | unsigned integer | infinite  | max number of elements |
`length`     | `list_of`      | unsigned integer | undefined | number of elements |
`required`   | `composed_of`  | unsigned integer | length of `composed_of` list | first `required` elements of the list must always be present |
`required`   | `labeled_list` | list of strings  | empty     | elements which must always be present |
`single`     | `labeled_list` | list of strings  | empty     | elements which can be present only once |
`predefined` | `tagged_list`| mapping (tagnames: typecodes) | empty | type of predefined tags |
`tagnames`   | `tagged_list`| string | `[A-Za-z_][0-9A-Za-z_]*` | regular expression for validation of tagnames |

## Format of the represented data

| Key | Definition kinds | Value type | Default | Purpose |
| --- | ---              | ---        | ---     | ---     |
| `empty`     | all | any | undefined | data value if element is missing in text repr. |
| `as_string` | all | boolean | false | if set, definition is used only for validation |
| `wrapped` | `one_of` | boolean | false | augment decoded value with branch names |
| `branch_names` | `one_of` | list of strings | ref.names/`[n]` | names of the branches to use for `wrapped` |
| `hide_constants` | `composed_of` | boolean | if set, elements of type `constant` are not used in the decoded value |
| `implicit` | `composed_of`, `labeled_list`, `tagged_list` | mapping (keys: values) | constant entries to add to decoded data |

## Numeric datatype intervals

Note: given in map under definition kind, e.g. `{integer: {min: ...}}`

| Key | Definition kinds | Value type | Default | Purpose |
| --- | ---              | ---        | ---     | ---     |
| `min` | `integer` | integer | -infinite | minimum valid data value |
| `max` | `integer` | integer | infinite | maximum valid data value |
| `min` | `unsigned_integer` | unsigned integer | 0 | minimum valid data value |
| `max` | `unsigned_integer` | unsigned integer | infinite | maximum valid data value |
| `min` | `float` | float | -infinite | data value must be > or >= `min` |
| `min_excluded` | `float` | boolean | false | value given as `min` is not included in valid data range |
| `max` | `float` | float | infinite | data value must be < or <= `max` |
| `max_excluded` | `float` | boolean | false | value given as `max` is not included in valid data range |

# String types

| Datatype kind              | Example               | Encoded   | Decoded      |
| -------------------------- | --------------------- | --------- | ------------ |
String constant              | `constant: abc`       | abc       | "abc"        |
Constant with mapping        | `constant: {1: true}` | 1         | true         |
Possibly absent constant     | `constant: {+: true}, empty: false` | + or "" | true or false |
One of a set of values (1)      | `values: [a, 1, {x: true}], empty: false`   | a, 1, x, "" | "a", 1, true, false |
Regex                 | `regex: '\d{2,3}'` | 10, 100 | "10", "100" |
Regex with mapping    | `regex: {'[Tt]rue': true}, canonical: "True", empty: false` | True, true, "" | true, true, false |
Multiple regexes      | `regexes: ["\d{2,3}", "A", "x\d"]` | 10, "A", x2 | "10", "A", "x2" |
Multiple regexes with mappings | `regexes: {"[Tt1]": true}, "[Ff0]": false},` <br/> `canonical: {"T": true, "F": false}` | "T", "t", "F" | true, true, false |

(1) Not all values must be strings, e.g. in the given examples, 1 is numeric

# Numeric types

| Datatype kind              | Example               | Encoded   | Decoded      |
| -------------------------- | --------------------- | --------- | ------------ |
Numeric constant (int/float) | `constant: 1`         | 1         | 1            |
Numeric set of values        | `values: [1, 2, 3]`   | 1, 2, 3   | 1, 2, 3      |
Numeric values with mapping  | `values: [0: false, 1: true]` | 0, 1 | false, true |
Strings mapped to numbers    | `values: ["I": 1, "II": 2]` | I, II | 1, 2 |
Any integer                  | `integer` | -20, 20, +20 | -20, 20, 20 |
Any integer, possibly absent | `integer: {}, empty: 0` | "", 1 | 0, 1 |
Integer lower than x         | `integer: {max: 100}` | 20 | 20 |
Integer higher than x        | `integer: {min: -10}` | 20 | 20 |
Integer in an interval       | `integer: {min: -10, max: 100}` | 20 | 20 |
Any unsigned integer         | `unsigned_integer` | 0, 10 | 0, 10 |
" possibly absent            | `unsigned_integer: {}, empty: 0` | 1, "" | 1, 0 |
" in an interval             | `unsigned_integer: {min: 1, max: 3}` | 3 | 3 |
" base 2                     | `unsigned_integer: {base: 2}` | 10, 0b10, 0B10, 0B1_0 | 2 |
" base 8                     | `unsigned_integer: {base: 8}` | 10, 0o10, 0O10, 0o1_0 | 8 |
" base 16                    | `unsigned_integer: {base: 16}` | FF, 0xFF, 0XFF, #FF, 0XF_F | 255 |
Any floating point           | `float` | 1, 0.2E-10 | 1, 0.2E-10 |
" possibly absent            | `float: {}, empty: 100` | 1E-2, "" | 1E-2, 100 |
" in an interval             | `float: {min: 1.2, max: 1.3}` | 1.3 | 1.3 |
" in an open interval        | `float: {min_excluded: true, min: 1}` | 1.01 | 1.01 |

# Multiple alternative definitions for an element

|                                |                                             |
| ------------------------------ | ------------------------------------------- |
Multiple alternative definitions | `one_of: [def1, def2]`
" giving definition inline       | `one_of: [{constant: "XYZ"}, def2]`
" allowing absence of value      | `one_of: [def1, def2], empty: "X"`
&nbsp;                           | &nbsp;
Explicit branch information      | `one_of: [def1, def2], wrapped: true`
-> for references to definitions | e.g. "XYZ" -decode-> {"def1": "XYZ"}
-> for n-th inline def (-> [n])  | e.g. "XYZ" -decode-> {"[1]": "XYZ"}
-> manually setting branch names | `, branch_names: [d1, d2]` => {"d1": "XYZ"}

# Kind of compound definitions

| Kind          | Elem. datatype   | Elem. semantic   | Data value type |
| ---           | ---              | ---              | ---
`list_of`       | constant         | constant         | list
`composed_of`   | ordinal position | ordinal position | mapping
`labeled_list`  | name             | name             | mapping
`tagged_list`   | typecode         | tagname          | mapping

| Kind          | Formatting keys                     | Validation keys
| ---           | ---                                 | ---
(common)        | `prefix`, `suffix`                  |
`list_of`       | `separator`/`splitted_by`           | `length`, `min_length`, `max_length`
`composed_of`   | `separator`/`splitted_by`           | `required`
`labeled_list`  | `internal_separator`, `splitted_by` | `single`, `required`
`tagged_list`   | `internal_separator`, `splitted_by` | `predefined`, `tagnames`

# Lists

|                                       |                                      |
| ------------------------------------- | ------------------------------------ |
List, separator never found in elements | `list_of: integer, splitted_by: ";"`
List, separator can be in elements (1)  | `list_of: integer, separator: "+"`
List, without separator (1)             | `list_of: {regex: "\d{2}"}`
&nbsp;                                  | &nbsp;
Strings surrounding list                | `list_of: x, prefix: "[", suffix: "]"`
&nbsp;                                  | &nbsp;
List with fixed length                  | `list_of: x, length: 1`
Minimum length (default: 1)             | `list_of: x, min_length: 0`
Maximum length (default: infinite)      | `list_of: x, max_length: 100`
&nbsp;                                  | &nbsp;
Validate, but do not parse list content | `list_of: x, as_string: true`

(1) parsed from left to right, greedyly

# Sequences

|                                       |                                      |
| ------------------------------------- | ------------------------------------ |
Sequence of elements, no separator (1)  | `composed_of: [elem1: def1, elem2: def2]`
Separator not found in elements         | `..., splitted_by: ":"`
Separator can be in elements (1)        | `..., separator: ":"`
&nbsp;                                  | &nbsp;
Multiple separators                     | `composed_of: [elem1: def1, sep12: {constant: '-'},` <br/> `  elem2: def2, sep23: {constant: ','}, elem3: def3],` <br/> `  hide_constants: true`
&nbsp;                                  | &nbsp;
Strings surrounding sequence            | `..., prefix: "[", suffix: "]"`
&nbsp;                                  | &nbsp;
Allow elems after first 3 to be absent  | `..., required: 3`
&nbsp;                                  | &nbsp;
Implicit values, not in text repr       | `composed_of: [v1: integer, v2: string], implicit: {v3: "x"}` <br/> 123a => {v1: 123, v2: "a", v3: "x"}
&nbsp;                                  | &nbsp;
Validate, but do not parse seq content  | `..., as_string: true`

# Labeled values list

|                                        |                                                          |
| ---------------------------------------| -------------------------------------------------------- |
Labeled values list                      | `labeled_list: {i: integer, f: float}, splitted_by: " "` <br/> e.g. i:12 f:3.2
" w. label-value separator other than :  | `...,internal_separator: "="` e.g. i=12 f=3.2
&nbsp;                                   | &nbsp;
Default: each label present 0,1,>1 times |
-> require some labels                   | `..., required: [f, f2, f3]`
-> allow some labels only once           | `..., single: [i, i2, i3]`
&nbsp;                                   | &nbsp;
Strings surroundings labeled values list | `..., prefix: "[", suffix: "]"`
&nbsp;                                   | &nbsp;
Strings surroundings labeled values list | `..., prefix: "[", suffix: "]"`
Validate, but do not parse list content  | `..., as_string: true`

# Tagged values list

|                                        |                                                          |
| ---------------------------------------| -------------------------------------------------------- |
Tagged values list                       | `tagged_list: {i: integer, f: float}, splitted_by: " "` <br/> e.g. AZ:i:12 XY:f:3.2
" with internal separator other than :   | `...,internal_separator: "="` e.g. AZ=i=12
" with tagnames other than SAM-style     | `..., tagnames: "[ABC][1-9][A-Z]"`
&nbsp;                                   | &nbsp;
Tagnames with predefined type            | `predefined: {"AB": "i", "XY": "f"}`
Accept only predefined tagnames          | `tagnames: "", predefined: {...`
&nbsp;                                   | &nbsp;
Strings surrounding tag list             | `..., prefix: "[", suffix: "]"`
&nbsp;                                   | &nbsp;
Validate, but do not parse list content  | `..., as_string: true`

# File parsing, definition scope

|                                  |                                    |
| -------------------------------- | ---------------------------------- |
Definition of a line               | `..., scope: line`
Definition of a fixed n of lines   | `..., scope: unit, n_lines: 3`
Definition of a section of a file  | `..., scope: section`
Definition of an entire file       | `..., scope: file`

# Testdata syntax

|                    |                                                         |
| ------------------ | ------------------------------------------------------- |
Structure            | `testdata: {datatype1: {...}, datatype2: {...}, ...}`
Tests for a datatype | `datatype1: {valid: ..., invalid: ...}`
-> decoded as string | `valid ["1", "2", "3"], invalid: [1, "x"]`
-> other kind of values | `valid: {"1": 1, "2": 2}, invalid: ["", true]`
-> non-canonical repr. | `datatype1: {valid: ..., oneway: ..., invalid: ...}` <br/> e.g. `valid: [1], oneway: {"+1": 1}`

