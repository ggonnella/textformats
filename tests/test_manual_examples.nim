##
## Test the examples provided in the manuals
##

import unittest
import textformats
import tables, json

suite "examples_in_Nim_API_manual":
  test "quick_tutorial":
    let
      mydatatypedef = %{"list_of": "unsigned_integer",
                        "splitted_by": "--"}.to_table
      specdata = %{"datatypes": {"mydatatype": mydatatypedef}}.to_table
      s = parse_specification($specdata)

    let d = s.get_definition("mydatatype")

    let
      encoded_input = "1--2--3"
      decoded_input = %[1, 2, 3]
      decoded = encoded_input.decode(d)
      encoded = decoded_input.encode(d)
    check decoded == decoded_input
    check encoded == encoded_input

