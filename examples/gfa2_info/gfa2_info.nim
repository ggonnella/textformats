import os, strutils, strformat, json
import textformats
import gfa2_stats_collector, gfa2_cross_validator

const HelpMsg = """
Validates a GFA2 file and display content statistics

Usage: $# <inputfile> <gfa2spec>

Arguments:
  <inputfile>  Input file in GFA2 format
  <gfa2spec>   Specification file describing the GFA2 format
"""

proc stats_collector_process_gfaline(line: JsonNode,
                                     stats_collector: var Gfa2StatsCollector) =
  stats_collector.lt(line["line_type"].getStr())
  if line["line_type"].getStr() == "segment":
    stats_collector.seq(line["slen"].getInt(),
                        line["sequence"].kind == JString)
  if "tags" in line:
    for tn, content in line["tags"]:
      stats_collector.tag(tn, content["type"].getStr())

type Data = ref object
  stats_collector*: Gfa2StatsCollector
  validator*: Gfa2CrossValidator

proc process_gfaline(line: JsonNode, dataptr: pointer) =
  var data = cast[Data](dataptr)
  stats_collector_process_gfaline(line, data.stats_collector)
  data.validator.process_gfaline(line)

proc parse_args(): (string, Specification) =
  if (paramCount() != 2):
    echo(HelpMsg % [getAppFilename()])
    quit(0)
  result[0] = paramStr(1)
  result[1] = specification_from_file(paramStr(2))

when isMainModule:
  #try:
    let
      (input_file, spec) = parse_args()
      ddef = get_definition(spec, "line")
    var
      validator = newGfa2CrossValidator()
      stats_collector = newGfa2StatsCollector(validator.ids)
      data = Data(validator: validator, stats_collector: stats_collector)
    input_file.decode_file(ddef, false, process_gfaline,
                           cast[pointer](data), DplWhole)
    data.validator.post_validations()
    if data.validator.n_err > 0:
      stderr.write("GFA2 cross-validations failed\n")
      stderr.write(&"Total number of errors: {data.validator.n_err}\n")
      quit(1)
    else:
      echo(data.stats_collector)
      quit(0)
    quit(0)
  #except:
  #  echo(getCurrentExceptionMsg())
  #  quit(1)

