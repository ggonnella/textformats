#!/usr/bin/env python3
import os
from textformats import Specification

testdir = os.path.dirname(os.path.realpath(__file__))
specfile = testdir + "/../../bio/spec/gfa2/gfa2.datatypes.yaml"
spec = Specification(specfile)
gfa2_position = spec["gfa2_position"]

decoded = gfa2_position.decode("2$")
print(decoded)
print(gfa2_position.is_valid_decoded(decoded))

encoded = gfa2_position.encode(decoded)
print(encoded)
print(gfa2_position.is_valid_encoded(encoded))

