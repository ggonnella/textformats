import unittest
import textformats/support/tables_support
import tables

suite "tables_support":
  test "keys_string":
    check $({"a": 1, "b": 2}.to_table.keys_string) == "[a, b]"

