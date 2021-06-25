% TF\_DECODE(1) tf\_decode 1.0.0
% Giorgio Gonnella
% June 2021

# NAME

tf\_decode - decode text representation, according to given datatype definition

# SYNOPSIS

**tf_decode** string -s SPECFILE -t DATATYPE -e ENCODED\
**tf_decode** (units|lines) -s SPECFILE -t DATATYPE -i INFILE\
**tf_decode** linewise -s SPECFILE -t DATATYPE [-i INFILE] [-w] [-g N]

# DESCRIPTION

The input of the command is a string or a text file, which contains data in a
format described in a *TextFormats* specification.

The output of the command is the decoded data, in JSON format.

The required arguments select the specification file (-s) and which datatype of
the specification to be used (-t).

# OPTIONS

## Subcommands

**string**
: decode an encoded string and output as JSON

**linewise**
: decode lines of a file using the specification

**units**
: decode file as list\_of units, defined by 'composed\_of'

**lines**
: decode file line-by-line as defined by 'composed\_of'

## Common options
**-s**, **--specfile=**FILENAME
: specification file to use, YAML or preprocessed (REQUIRED
  except for *linewise*, if the specification is embedded
  in the input file

**-t**, **--datatype=**DATATYPE
: which datatype to use, among those defined by the specification (REQUIRED)

## Subcommand-specific options

*string* subcommand:

**-e**, **--encoded=**STRING
: encoded string to be decoded (REQUIRED)

*linewise*, *units*, *lines* subcommands:

**-i**, **--infile=**FILENAME
: input file, containing the encoded data and, if **-s** is not used,
  an embedded specification (REQUIRED)

# EXIT VALUES
The exit code is 0 on success, anything else on error.
