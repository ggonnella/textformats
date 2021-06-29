% TF\_VALIDATE(1) tf\_validate 1.0.0
% Giorgio Gonnella
% June 2021

# NAME

tf\_validate - validate data according to a given datatype definition

# SYNOPSIS

**tf\_validate** encoded -s SPECFILE -t DATATYPE -e ENCODED\
**tf\_validate** decoded -s SPECFILE -t DATATYPE -d DECODED\

# DESCRIPTION

The command can be used to test if data is valid according to a given
datatype definition.

The data can be either provided as encoded, i.e. as the text representation
described by the datatype definition, or decoded (as string in JSON format).

# OPTIONS

## Subcommands

**encoded**
: validate data encoded according to the datatype definition

**decoded**
: validate decoded data (provided as JSON) according to the datatype definition

## Common options
**-s**, **\-\-specfile=**FILENAME
: specification file to use, YAML or preprocessed (REQUIRED)

**-t**, **\-\-datatype=**DATATYPE
: which datatype to use among those defined by the specification
  (default: datatype with name 'default')

## Subcommand-specific options

*decoded* subcommand:

**-e**, **\-\-encoded**=STRING
: encoded data (in the specified text representation) to be validated
(REQUIRED)

*encoded* subcommand:

**-d**, **\-\-decoded\_json**=STRING
: decoded data (as JSON) to be validated (REQUIRED)

# EXIT VALUES
The exit code is 0 on validation success, anything else on validation
failure or error.
