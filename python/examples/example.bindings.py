#!/usr/bin/env python3
import os
import nimporter
from textformats.py_bindings import *

testdir = os.path.dirname(os.path.realpath(__file__))
gfa2_specfile = testdir + "/../../bio/spec/gfa/gfa2.yaml"
gfa2_pspecfile = testdir + "/gfa2.tfs"
gfa2_datafile = testdir + "/../../bio/data/test.gfa2"
fasta_specfile = testdir + "/../../bio/spec/fasta.yaml"
fasta_datafile = testdir + "/../../bio/data/test.fas"
fastq_specfile = testdir + "/../../bio/spec/fastq.yaml"
fastq_datafile = testdir + "/../../bio/data/test.fq"

preprocess_specification(gfa2_specfile, gfa2_pspecfile)
print(is_preprocessed(gfa2_specfile))
print(is_preprocessed(gfa2_pspecfile))
gfa2_spec = specification_from_file(gfa2_specfile)

gfa2_position = get_definition(gfa2_spec, "gfa2::position")
print(describe(gfa2_position))

decoded = decode("2$", gfa2_position)
print(decoded)
print(is_valid_decoded(decoded, gfa2_position))

encoded = encode(decoded, gfa2_position)
print(encoded)
print(is_valid_encoded(encoded, gfa2_position))

#gfa2_line = get_definition(gfa2_spec, "line")
#for line in decoded_lines(gfa2_datafile, gfa2_line):
#  print(line)
#
fasta_spec = specification_from_file(fasta_specfile)
run_specification_testfile(fasta_spec, fasta_specfile)

fasta_entry = get_definition(fasta_spec, "entry")

for section in decoded_sections(fasta_datafile, fasta_entry):
  print(section)

for element in decoded_section_elements(fasta_datafile, fasta_entry):
  print(element)

fasta_file_def = get_definition(fasta_spec, "file")

print(decoded_whole_file(fasta_datafile, fasta_file_def))

for element in decoded_whole_file_elements(fasta_datafile, fasta_file_def):
  print(element)


#fastq_spec = specification_from_file(fastq_specfile)
#fastq_entry = get_definition(fastq_spec, "fastq_entry")
#for unit in decoded_units(fastq_datafile, fastq_entry, 4):
#  print(unit)
#for unit in decoded_units(fastq_specfile, fastq_entry, 4, True):
#  print(unit)


