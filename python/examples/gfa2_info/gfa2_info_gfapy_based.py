#!/usr/bin/env python3
"""
Validates a GFA2 file and display content statistics
(version based on GfaPy)

Usage: ./gfa2_info_gfapy_based.py <inputfile>

Arguments:
  <inputfile>  Input file in the GFA2 format
"""
from docopt import docopt
from gfapy import Gfa, is_placeholder
from gfa2_stats_collector import Gfa2StatsCollector

LTYPES = {"S": "segment", "H": "header", "E": "edge", "G": "gap",
          "F": "fragment", "O": "ordered_group", "U": "unordered_group",
          "#": "comment"}

def process_gfaline(line, stats_collector):
  lt = LTYPES.get(line.record_type, "custom_line")
  if lt != "header":
    stats_collector.lt(lt)
  if lt == "segment":
    stats_collector.segment(line.sid)
    stats_collector.seq(line.slen, not is_placeholder(line.sequence))
  elif lt in ["edge", "gap"]:
    stats_collector.sref(line.sid1.sid)
    stats_collector.sref(line.sid2.sid)
  elif lt == "fragment":
    stats_collector.sref(line.sid.sid)
  elif lt == "ordered_group":
    for e in line.items:
      if e.record_type == "S":
        stats_collector.sref(e.sid)
  elif lt == "unordered_group":
    for e in line.items:
      if e.record_type == "S":
        stats_collector.sref(e.sid)
  for tn in line.tagnames:
    tt = line.get_datatype(tn)
    stats_collector.tag(tn, tt)

def main(args):
  stats_collector = Gfa2StatsCollector()
  gfa = Gfa.from_file(args["<inputfile>"])
  for line in gfa.lines:
    process_gfaline(line, stats_collector)
  stats_collector.lt("header", gfa.n_input_header_lines)
  print(stats_collector, end="")

if __name__ == "__main__":
  args = docopt(__doc__)
  main(args)
