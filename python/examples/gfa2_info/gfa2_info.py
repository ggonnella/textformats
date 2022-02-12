#!/usr/bin/env python3
"""
Validates a GFA2 file and display content statistics

Usage: ./gfa2_info.py <inputfile> <gfa2spec>

Arguments:
  <inputfile>  Input file in GFA2 format
  <gfa2spec>   Specification file describing the GFA2 format
"""
from textformats import Specification
from docopt import docopt
from gfa2_stats_collector import Gfa2StatsCollector
from gfa2_cross_validator import Gfa2CrossValidator
import sys

def stats_collector_process_gfaline(line, stats_collector):
  stats_collector.lt(line["line_type"])
  if line["line_type"] == "segment":
    stats_collector.seq(line["slen"], line["sequence"] is not None)
  for tn, content in line.get("tags", {}).items():
    stats_collector.tag(tn, content["type"])

def process_gfaline(line, data):
  stats_collector, validator = data
  stats_collector_process_gfaline(line, stats_collector)
  validator.process_gfaline(line)

def main(args):
  gfa2spec = Specification(args["<gfa2spec>"])
  validator = Gfa2CrossValidator()
  stats_collector = Gfa2StatsCollector(validator.ids)
  gfa2spec["line"].decode_file(args["<inputfile>"], process_gfaline,
                               (stats_collector, validator))
  validator.post_validations()
  if validator.n_err > 0:
    sys.stderr.write(f"GFA2 cross-validations failed\n")
    sys.stderr.write(f"Total number of errors: {validator.n_err}\n")
    sys.exit(1)
  else:
    print(stats_collector, end="")
    sys.exit(0)

if __name__ == "__main__":
  args = docopt(__doc__)
  main(args)
