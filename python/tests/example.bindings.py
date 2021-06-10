#!/usr/bin/env python3
import os
import nimporter
from textformats.py_bindings import *

testdir = os.path.dirname(os.path.realpath(__file__))
specfile = testdir + "/../../bio/spec/gfa2/gfa2.datatypes.yaml"
spec = parse_specification(specfile)
gfa2_position = get_definition(spec, "gfa2_position")
decoded = decode("2$", gfa2_position)
print(decoded)
print(is_valid_decoded(decoded, gfa2_position))
encoded = encode(decoded, gfa2_position)
print(encoded)
print(is_valid_encoded(encoded, gfa2_position))

