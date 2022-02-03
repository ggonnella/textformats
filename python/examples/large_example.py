#!/usr/bin/env python3
import os
from textformats import Specification, DECODED_PROCESSOR_LEVEL

testdir = os.path.dirname(os.path.realpath(__file__))
specdir = testdir + "/../../spec"
biotestdir = testdir + "/../../tests/testdata/bio"

header = ">ABCD some sequence"
decoded_header = {"fastaid": "ABCD", "desc": "some sequence"}
decoded_header_json = "{\"fastaid\":\"ABCD\",\"desc\":\"some sequence\"}";

print(f"Encoded: {header}")
spec = Specification(f"{specdir}/fasta.yaml")
assert(not spec.is_compiled)
print("Spec fasta.yaml is not compiled")
spec.compile(f"{specdir}/fasta.yaml", "fasta.tfs")
spec = Specification("fasta.tfs")
assert(spec.is_compiled)
print("Spec fasta.tfs is compiled")
spec.test(f"{specdir}/fasta.yaml")

fas_entry = spec["default"]
fas_header = spec["header"]
print(fas_header)
print(spec.datatype_names)

print(fas_header.decode(header))
print(fas_header.decode(header, True))
assert(fas_header.is_valid_encoded(header))
print(f"\"{header}\" is a valid encoded fas_header")
print(fas_header.encode(decoded_header_json, True))
print(fas_header.encode(decoded_header))
assert(fas_header.is_valid_decoded(decoded_header))
print(f"\"{decoded_header_json}\" is a valid decoded fas_header")

def decoded_processor(decoded, processor_data):
  print(f"Decoded value: {decoded}")

print("\nDecode file, level \"whole\"")
fas_entry.decode_file(f"{biotestdir}/test.fas", decoded_processor,
    None, DECODED_PROCESSOR_LEVEL.WHOLE)
print("\nDecode file, level \"element\"")
fas_entry.decode_file(f"{biotestdir}/test.fas", decoded_processor,
    None, DECODED_PROCESSOR_LEVEL.ELEMENT)
print("\nDecode file, level \"line\"")
fas_entry.decode_file(f"{biotestdir}/test.fas", decoded_processor,
    None, DECODED_PROCESSOR_LEVEL.LINE)
