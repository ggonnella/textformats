# Benchmarks

## Parsing CIGAR strings in a file

Each line of a file contains CIGAR strings, with an average of 100 operations
per line.  The operations in the CIGARs are only M, I and D.

A program shall:
- read the file and process it line by line
- construct in memory a representation of the CIGAR as list of operations
- each operation shall be a struct/object consisting of
  code (char) and length (unsigned integer)
- an empty line shall be accepted (empty list)

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
M={%lu,%lu,%lu,%lu},I={%lu,%lu,%lu,%lu},D={%lu,%lu,%lu,%lu}

The TextFormats specification for reading the format is
`benchmarks/data/cigars.yaml` (datatype: default).
