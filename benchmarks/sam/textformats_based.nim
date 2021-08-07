import strutils, os, tables, json, strformat
import textformats

const HelpMsg = """
Usage: $# <sam> <spec> <datatype>

Arguments:
  <sam>        SAM file
  <spec>       textformats specification
  <datatype>   datatype to use
"""

type
  Counts = ref object
    flag_counts: OrderedTableRef[int, int]
    tag_counts: OrderedTableRef[string, int]
    rg_counts: OrderedTableRef[string, int]
    rg_sm_values: TableRef[string, string]
    sq_counts: OrderedTableRef[string, int]

proc parse_args(): (string, DatatypeDefinition) =
  if (paramCount() != 3):
    echo(HelpMsg % [getAppFilename()])
    quit(0)
  let spec = specification_from_file(paramStr(2))
  result[0] = paramStr(1)
  result[1] = get_definition(spec, paramStr(3))

proc process_decoded(decoded: JsonNode, data: pointer) =
  var counts = cast[Counts](data)
  for key, value in decoded:
    case key:
      of "header.@SQ":
        let sq = value["SN"][0].getStr()
        counts.sq_counts[sq] = 0
      of "header.@RG":
        let
          rg_id = getStr(value["ID"][0])
          rg_sm = getStr(value["SM"][0])
        counts.rg_counts[rg_id] = 0
        counts.rg_sm_values[rg_id] = rg_sm
      elif key[0 .. 9] == "alignments":
        let
          flag = getInt(value["flag"])
          sq = getStr(value["rname"])
        counts.flag_counts.mget_or_put(flag, 0) += 1
        if sq notin counts.sq_counts:
          let msg = &"Error: Unknown target sequence found in alignment ({sq})"
          raise newException(ValueError, msg)
        counts.sq_counts[sq] += 1
        for tagname, tag in value["tags"]:
          counts.tag_counts.mget_or_put(tagname, 0) += 1
          if tagname == "RG":
            let
              tagcode = getStr(tag["type"])
              tagvalue = getStr(tag["value"])
            if tagcode != "Z":
              let msg = &"Error: RG tag code is not 'Z' but '{tagcode}'"
              raise newException(ValueError, msg)
            if tagvalue notin counts.rg_counts:
              let msg = &"Error: Unknown RG found in alignment ({tagvalue})"
              raise newException(ValueError, msg)
            counts.rg_counts[tagvalue] += 1

proc print_counts(counts: Counts) =
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
    let (input_file, ddef) = parse_args()
    var counts = Counts(flag_counts: newOrderedTable[int, int](),
                        tag_counts: newOrderedTable[string, int](),
                        rg_counts: newOrderedTable[string, int](),
                        rg_sm_values: newTable[string, string](),
                        sq_counts: newOrderedTable[string, int]())
    input_file.decode_file(ddef, false, process_decoded, cast[pointer](counts), DplLine)
    print_counts(counts)
    quit(0)
  except:
    echo(getCurrentExceptionMsg())
    quit(1)
