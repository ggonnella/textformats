% TF\_TEST(1) tf\_test 1.0.0
% Giorgio Gonnella
% June 2021

# NAME

tf\_test - test the results of encoding, decoding and validation for a given datatype

# SYNOPSIS

**tf\_test** decoding -s SPECFILE -t DATATYPE -e ENCODED -d EXPECTED \
**tf\_test** fail\_decoding -s SPECFILE -t DATATYPE -e ENCODED \

**tf\_test** encoding -s SPECFILE -t DATATYPE -d DECODED -e EXPECTED \
**tf\_test** fail\_encoding -s SPECFILE -t DATATYPE -d DECODED \

**tf\_test** decoded\_validation -s SPECFILE -t DATATYPE -d DECODED [-v] \
**tf\_test** encoded\_validation -s SPECFILE -t DATATYPE -e ENCODED [-v] \

# DESCRIPTION

The command can be used to test if the results of encoding, decoding and
validation using a given datatype fulfill the expectations.

It has the same purpose as the test data provided under ``testdata`` (see
also **tf\_spec generate_tests** and **tf\_spec test**), but is intended
for running a single test manually, instead of the entire test suite
automatically.

The available tests are decoding (subcommands **decoding** and
**fail\_decoding**), encoding (subcommands **encoding** and **fail\_encoding**),
validation of data, provided as encoded in the defined text representation
(subcommand **encoded\_validation**) or as decoded data in JSON format
(subcommand **decoded\_validation**).

# OPTIONS

## Subcommands

**decoding**
: test an encoded string and compare the result to the expected data (JSON)

**fail\_decoding**
: test that decoding the provided encoded string fails

**encoding**
: encode the decoded data (JSON) and compare to the expected encoding

**fail\_encoding**
: test that encoding the provided decoded data (JSON) fails

**encoded\_validation**
: test the validation of an encoded string

**decoded\_validation**
: test the validation of decoded data (JSON)

## Common options
**-s**, **\-\-specfile=**FILENAME
: specification file to use, YAML, JSON or compiled (REQUIRED)

**-t**, **\-\-datatype=**DATATYPE
: which datatype to use among those defined by the specification
  (default: datatype with name 'default')

## Input data options

*decoding*, *fail\_decoding*, *encoded\_validation* subcommands:

**-e**, **\-\-encoded**=STRING
: encoded data (in the specified text representation) to be decoded or validated
(REQUIRED)

*encoding, *fail\_encoding*, *decoded\_validation* subcommands:

**-d**, **\-\-decoded\_json**=STRING
: decoded data (as JSON) to be encoded or validated (REQUIRED)

## Expected results

*encoding* subcommand:

**-e**, **\-\-expected**=STRING
: encoded data which is expected as an output of the encoding (REQUIRED)

*decoding* subcommand:

**-d**, **\-\-expected\_json**=STRING
: encoded data which is expected as an output of the encoding (REQUIRED)

*encoded\_validation* and *decoded\_validation* subcommands:

**-v**, **\-\-expected\_valid**
: set this flag if the validation is expected to succeed (default:
  expect that the validation fails)

# EXIT VALUES
The exit code is 0 on success, anything else on error.

