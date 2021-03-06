% TF\_DECODE(1) tf\_decode 1.0.0
% Giorgio Gonnella
% June 2021

# NAME

tf\_decode - decode text representation, according to given datatype definition

# SYNOPSIS

**tf_decode** string -s SPECFILE [-t DATATYPE] -e ENCODED\
**tf_decode** file [-s SPECFILE] [t DATATYPE] -i INFILE [-c S] [-w] [-x] [-u N]\

# DESCRIPTION

The input of the command is a string or a text file, which contains data in a
format described in a *TextFormats* specification.

The output of the command is the decoded data, in JSON format.

## Specifications

The specification file is either a YAML, JSON or compiled specification.

For the *file* subcommand, the specification may also be embedded, i.e.
provided, as YAML/JSON, in the beginning of the file, separated from the data
by a YAML document separator, i.e. a line consisting of --- only.

If a specification contains a datatype named 'default', this is used by default,
and the **\-\-datatype** option is not required.

## Scope section/file

If the **\-\-scope** option is set to 'section' or 'file', the definition must
be of kind 'composed\_of', 'list\_of' or 'named\_values', or a reference to
one of those. The separator must be the newline, and prefix and suffix must be
empty. Parsing is greedy, i.e. as many lines as possible are assigned to
each element of the compound datatype.

# OPTIONS

## Subcommands

**string**
: decode an encoded string and output as JSON

**file**
: decode a file using the specification

## Common options
**-s**, **\-\-specfile=**FILENAME
: specification file to use, YAML/JSON or compiled
  (not required for *file*, if the specification is embedded
  in the input file; always required for *string*)

**-t**, **\-\-datatype=**DATATYPE
: which datatype to use, among those defined by the specification
  (default: use datatype named 'default')

## Subcommand-specific options

*string* subcommand:

**-e**, **\-\-encoded=**STRING
: encoded string to be decoded
  (default: standard input, or empty string if none)

*file* subcommands:

**-i**, **\-\-infile=**FILENAME
: input file, containing the encoded data and, if **-s** is not used,
  an embedded specification (default: standard input; embedded specifications
  are not supported in this case)

**-w**, **\-\-wrapped**
: if set, and the datatype definition is 'one\_of', the decoded
  value is wrapped in a single-entry mapping, where the key
  is the name of the 'one\_of' branch which has been used for
  decoding, and the value is the unwrapped decoded value

**-x**, **\-\-splitted**
: if set, and scope is 'file' or 'section', the file/section
  structure is used for parsing but the decoded value of each
  line is output separately; advantage: it does not require to
  keep the whole file or file section in memory; scope 'line'
  is similar, but the structure of the file/section is not defined
  (default: false; ignored if scope is not 'file' or 'section')

**-c**, **\-\-scope=**S
: which part of the input file is targeted by the datatype
  definition; default: 'auto' (as specified by the scope key of
  the definition); other accepted values:
  'line' (each line of the file by itself),
  'unit' (units of fixed number of lines; see \-\-unitsize),
  'section' (sections of variable number of lines,
             as many as possible fit the definition, greedy),
  'file' (the entire file)

**-u**, **\-\-unitsize=**N
: how many lines does a unit contain (required if scope is 'unit'
  and no 'n\_lines' key is given in the definition; ignored if
  scope is not 'unit')

# EXIT VALUES
The exit code is 0 on success, anything else on error.

