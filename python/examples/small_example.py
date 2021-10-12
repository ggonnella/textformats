#!/usr/bin/env python3
import os
from textformats import Specification
from textformats.error import DecodingError

testdir = os.path.dirname(os.path.realpath(__file__))
cigarsdir = testdir + "/../../benchmarks/data/cigars"

encoded = "1M100D1I2M3M4M"
encoded_wrong = "1M;100D1I2M3M4M"
print(f"Encoded: {encoded}")

# open specification and get datatype definition
spec = Specification(f"{cigarsdir}/cigars.yaml")
datatype = spec["cigar_str"]

# decode
decoded = datatype.decode(encoded)
print(f"[Decoding succeeded]\n{decoded}")

# failing decode example
try:
  datatype.decode(encoded_wrong)
except DecodingError as err:
  print(f"[DecodingError as expected]\n{err}")
