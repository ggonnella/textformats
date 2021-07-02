# datatype definition
import textformats/types/datatype_definition
export DatatypeDefinition
export `$`
export get_unitsize
export set_unitsize
export get_scope
export set_scope
export get_wrapped
export set_wrapped
export unset_wrapped

# specification
import textformats/types/specification
export Specification
export BaseDatatypes
export get_definition
export is_preprocessed
export datatype_names

import textformats/spec_parser
export specification_from_file
export preprocess_specification

# decoding
import textformats/decoder
export decode

import textformats/file_decoder
#
# iterators
#
# scope: line
export decoded_lines
# scope: unit
export decoded_units
# scope: section
export decoded_sections
export decoded_section_elements
# scope: file
export decoded_whole_file
export decoded_whole_file_elements
# scope: auto/specified
export decoded_file_values

# encoding
import textformats/encoder
export encode
export unsafe_encode

# test
import textformats/testdata_parser
export test_specification

# validation
import textformats / [decoded_validator, encoded_validator]
export is_valid

# exceptions
import textformats/types/textformats_error
export textformats_error

# workaround to avoid spurious warning in c_api
const avoid_module_unused_warning* = true
