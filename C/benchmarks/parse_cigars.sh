#!/bin/bash

cdir="../../bio/benchmarks/cigars/"
spec="$cdir/cigar.datatypes.yaml"
dt="cigar"
input="$cdir/100k_cigars_len100"
output="results"

>&2 echo "### Running parse_cigars ###"
>&2 echo "# Parameters:"
>&2 echo "#   Specification: $spec"
>&2 echo "#   Datatype:      $dt"
>&2 echo "#   Input file:    $input"
>&2 echo "#   Output file:   $output"
>&2 echo "# ... parsing cigars ..."
time ./parse_cigars $spec $dt $input decode > $output
