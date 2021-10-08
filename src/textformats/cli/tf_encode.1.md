% TF\_ENCODE(1) tf\_encode 1.0.0
% Giorgio Gonnella
% June 2021

# NAME

tf\_encode - encode data to a text representation, according to given datatype definition

# SYNOPSIS

**tf\_encode** json -s SPECFILE -t DATATYPE -d DECODED

# DESCRIPTION

The input of the command is the data, in JSON format.

The output of the command is a string, which represents the input data in a
format described in a *TextFormats* specification.

The required arguments select the specification file (-s) and which datatype of
the specification to be used (-t).

# OPTIONS

## Subcommands

**json**
: encode an input JSON string according to the datatype definition

## Options
**-s**, **\-\-specfile=**FILENAME
: specification file to use, YAML, JSON or compiled (REQUIRED)

**-t**, **\-\-datatype=**DATATYPE
: which datatype to use, among those defined by the specification
  (default: datatype with name 'default')

**-d**, **\-\-decoded_json=**STRING
: data (JSON format) to be encoded
  (default: standard input, or empty string if none)

# EXIT VALUES
The exit code is 0 on success, anything else on error.
