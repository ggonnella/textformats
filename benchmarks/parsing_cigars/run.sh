#!/bin/bash

if [ "$1" == "" ]; then
  >&2 echo "Missing argument: number of cigars"
  >&2 echo "accepted values are:"
  >&2 echo "- 10k"
  >&2 echo "- 100k"
  >&2 echo "- 1_million"
  >&2 echo "Anything else will lead to an error"
  exit 1
fi

cdir="../../bio/benchmarks/cigars/"
spec="$cdir/cigar.datatypes.yaml"
dt="cigar"
input="$cdir/$1_cigars_len100"
output="output.parse_cigars.$1"

if [ ! -e "$input" ]; then
  >&2 echo "File $input does not exist"
  >&2 echo "Invalid argument value $1"
  >&2 echo "accepted values are:"
  >&2 echo "- 10k"
  >&2 echo "- 100k"
  >&2 echo "- 1_million"
  exit 1
fi

>&2 echo "### Running parse_cigars ###"
>&2 echo "# Parameters:"
>&2 echo "#   Specification: $spec"
>&2 echo "#   Datatype:      $dt"
>&2 echo "#   Input file:    $input"
>&2 echo "#   Output file:   $output"
>&2 echo "# ... parsing cigars ..."
time ./parse_cigars -s=$spec -t=$dt -i=$input > $output
