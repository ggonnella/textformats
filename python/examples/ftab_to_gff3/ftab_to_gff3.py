#!/usr/bin/env python3
"""
This file implements an example application of TextFormats:
converting a custom formatted feature table describing a piece of a sequence
region into a standard GFF3 file.

Usage: ./ftab2gff3.py <inputfile> <ftabspec> <gff3spec> <seqid> <seqlen>

Arguments:
  <inputfile>  Input file in the custom format
  <ftabspec>   Specification file describing the custom format
  <gff3spec>   Specification file describing the GFF3 format
  <seqid>      Sequence region to use
  <seqlen>     Length of the sequence
"""
from textformats import Specification, DECODED_PROCESSOR_LEVEL
from docopt import docopt

def process_feature_line(node, data):
  line_type = list(node.keys())[0]
  if line_type.startswith("feature_line"):
    c = node[line_type]
    # (1) values not set in the custom format
    annotation = {"seqid": data["seqid"], "source": None, "score": None}
    # (2) gff3 columns equivalent to custom format
    for key in ["type", "start", "end", "phase", "strand"]:
      annotation[key] = c[key]
    # (3) gff3 attributes from custom format columns
    annotation["attributes"] = []
    attrtypes = {"ID": "single_id_attribute",
                 "Name": "single_id_attribute",
                 "Parent": "id_list_attribute"}
    for key, attrtype in attrtypes.items():
      if c[key]:
        annotation["attributes"].append(
            {attrtype: {"tag": key, "value": c[key]}})
    # append line to output
    print(data["gff3spec"]["annotation"].encode(annotation))

args = docopt(__doc__)
# parse specifications
ftabspec = Specification(args["<ftabspec>"])
gff3spec = Specification(args["<gff3spec>"])

# gff3 header data
version = {"version": "3", "major_revision": 1, "minor_revision": 26}
print(gff3spec["version_directive"].encode(version))
sregion = {"seqid": args["<seqid>"], "start": 1, "end": int(args["<seqlen>"])}
print(gff3spec["sequence_region_directive"].encode(sregion))

# annotation lines from custom format
ftabspec["file"].decode_file(
    args["<inputfile>"], process_feature_line,
    {"seqid": args["<seqid>"], "gff3spec": gff3spec},
    DECODED_PROCESSOR_LEVEL.LINE)
