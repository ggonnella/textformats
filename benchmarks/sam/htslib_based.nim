import strutils, os, tables, strformat
import hts

const HelpMsg = """
Usage: $# <sam>

Arguments:
  <sam>        SAM file
"""

type
  Counts = ref object
    flag_counts: OrderedTableRef[int, int]
    tag_counts: OrderedTableRef[string, int]
    rg_counts: OrderedTableRef[string, int]
    rg_sm_values: TableRef[string, string]
    sq_counts: OrderedTableRef[string, int]

proc parse_args(): Bam =
  if (paramCount() != 1):
    echo(HelpMsg % [getAppFilename()])
    quit(0)
  open(result, paramStr(1))
  return result

proc parse_header(input_file: Bam, counts: Counts) =
  for line in ($input_file.hdr).split_lines():
    let fields = line.split("\t")
    if fields[0] == "@RG":
      var rg_id: string
      for field in fields:
        let
          k_v = field.split(":", 1)
          k = k_v[0]
          v = k_v[1]
        if k == "ID":
          rg_id = v
          counts.rg_counts[rg_id] = 0
        elif k == "SM":
          counts.rg_sm_values[rg_id] = v

proc parse_tags(aln: hts.bam.Record, counts: Counts) =
  var i = 0
  for field in to_string(aln).split("\t"):
    if i > 10:
      let tagname = field.split(":", 1)[0]
      counts.tag_counts.mget_or_put(tagname,
       0) += 1
    i += 1

proc process_sam_file(input_file: Bam, counts: Counts) =
  parse_header(input_file, counts)
  for t in targets(input_file.hdr):
    counts.sq_counts[t.name] = 0
  for aln in input_file:
    counts.flag_counts.mget_or_put(aln.flag.int, 0) += 1
    let sq = aln.chrom
    if sq notin counts.sq_counts:
      let msg = &"Error: Unknown target sequence found in alignment ({sq})"
      raise newException(ValueError, msg)
    counts.sq_counts[sq] += 1
    var rg = tag[string](aln, "RG")
    if not rg.isNone:
      if rg.get notin counts.rg_counts:
        let msg = &"Error: Unknown RG found in alignment ({rg.get})"
        raise newException(ValueError, msg)
      counts.rg_counts[rg.get] += 1
    parse_tags(aln, counts)

proc print_counts(counts: Counts, header: hts.bam.Header) =
  echo("alignments by target sequence:")
  for k, v in counts.sq_counts:
    echo &"  {k}: {v}"
  echo("alignments by read group:")
  for k, v in counts.rg_counts:
    let sm = counts.rg_sm_values[k]
    echo &"  {k} (SM:{sm}): {v}"
  echo("tag counts:")
  for k, v in counts.tag_counts:
    echo &"  {k}: {v}"
  echo("alignments by flag value:")
  for k, v in counts.flag_counts:
    echo &"  {k}: {v}"

when isMainModule:
  try:
    let input_file = parse_args()
    var counts = Counts(flag_counts: newOrderedTable[int, int](),
                        tag_counts: newOrderedTable[string, int](),
                        rg_counts: newOrderedTable[string, int](),
                        rg_sm_values: newTable[string, string](),
                        sq_counts: newOrderedTable[string, int]())
    process_sam_file(input_file, counts)
    print_counts(counts, input_file.hdr)
    quit(0)
  except:
    echo(getCurrentExceptionMsg())
    quit(1)
