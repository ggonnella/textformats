#!/usr/bin/env python3
import os
from textformats import Specification

testdir = os.path.dirname(os.path.realpath(__file__))
specfile = testdir + "/../../spec/gfa/gfa2.yaml"
spec = Specification(specfile)
gfa2_position = spec["gfa2::position"]

decoded = gfa2_position.decode("2$")
print(decoded)
print(gfa2_position.is_valid_decoded(decoded))

encoded = gfa2_position.encode(decoded)
print(encoded)
print(gfa2_position.is_valid_encoded(encoded))

