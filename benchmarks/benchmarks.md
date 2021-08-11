# Benchmarks

## Parsing CIGAR strings in a file

Each line of a file contains CIGAR strings, with an average of 100 operations
per line. The operations in the CIGARs are only M, I and D.

A program shall:
- read the file and process it line by line
- construct in memory a representation of the CIGAR as list of operations
- each operation shall be a struct/object consisting of
  code (char or string) and length (integer)

The program shall validate:
- the codes are correct (M, I or D)
- the length string is composed of digits, not starting with a zero
- the length can be parsed as an integer and is > 0

The following shall be computed, for each operation code:
- the number of operations with that code
- the total length of the operations with that code
- the minimal length of an operation with that code
- the maximal length of an operation with that code
and output it using this format:
M={%lu:%lu..%lu;sum=%lu},I={%lu:%lu..%lu;sum=%lu},D={%lu:%lu..%lu;sum=%lu}

The TextFormats specification for reading the format is
`benchmarks/data/cigars/cigars.yaml` (datatype: `cigar_str`).

## Parsing SAM file

The program shall validate that:
- all alignment target sequences have a corresponding SQ line in the header
- all alignment RG tags have a corresponding RG line in the header

Compute some statistics about a SAM file:
  - count alignments by target sequence (output in the order they are found
    in the SAM file header SQ lines)
  - count alignments by read group (output in the order they are found
    in the SAM file header RG lines; add the values of the SM tags of the header
    RG line to the output)
  - count tags occurrences in alignments (output in the order the tags are found
    in the file)
  - count alignments by flag value (combined, int value); output in the order
    flags are found in the alignments in the file

Output format:
```
alignments by target sequence:
  <SEQID>: <n>
  <SEQID>: <n>
  ...
alignments by read group:
  <RG_ID> (SM:<RG_SM>): <n>
  <RG_ID> (SM:<RG_SM>): <n>
  ...
tag counts:
  <TAGNAME>: <n>
  ...
alignments by flag value:
  <FLAG>: <n>
  ...
```

The program shall be implemented using TextFormats or, respectively, using `htslib`
(or a wrapper to it, such as `hts-nim` in Nim and `pysam` in Python).
