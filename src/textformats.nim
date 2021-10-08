# datatype definition
import textformats/types/datatype_definition
export DatatypeDefinition
export get_unitsize
export set_unitsize
export get_scope
export set_scope
export get_wrapped
export set_wrapped
export unset_wrapped

# introspection
import textformats/introspection
export `$`
export `repr`

# specification
import textformats/types/specification
export Specification
export BaseDatatypes
export get_definition
export is_compiled
export datatype_names

import textformats/spec_parser
export specification_from_file
export parse_specification
export compile_specification

# decoding
import textformats/decoder
export decode

import textformats/file_decoder
export decoded_file
export decode_file
export DecodedProcessorLevel

# encoding
import textformats/encoder
export encode

# test
import textformats/testdata_parser
export run_specification_testfile
export run_specification_tests

# validation
import textformats / [decoded_validator, encoded_validator]
export is_valid

# exceptions
import textformats/types/textformats_error
export textformats_error

# workaround to avoid spurious warning in c_api
const avoid_module_unused_warning* = true
