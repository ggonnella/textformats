#!/usr/bin/env bash

PATH=${PATH}:${PWD}/..

specdir="../../spec"
biotestdir="../../tests/testdata/bio"
header=">ABCD some sequence"
decoded_header="{\"fastaid\": \"ABCD\", \"desc\": \"some sequence\"}"

echo "Encoded: $header"
tf_spec compile -s $specdir/fasta.yaml -o fasta.tfs
if [ $? -ne 0]; then echo "ERROR Line $LINENO"; exit 1; fi
echo "Spec fasta.tfs compiled successfully"

tf_spec test -s fasta.tfs -f $specdir/fasta.yaml
tf_spec info -s fasta.tfs -t header
tf_spec info -s fasta.tfs

tf_decode string -s fasta.tfs -t header -e "$header"
tf_validate encoded -s fasta.tfs -t header -e "$header"

tf_encode json -s fasta.tfs -t header -d "$decoded_header"
tf_validate decoded -s fasta.tfs -t header -d "$decoded_header"

echo
echo Decode file, level \"line\"
tf_decode file -s fasta.tfs -i $biotestdir/test.fas
echo
echo Decode file, level \"whole\"
tf_decode file -s fasta.tfs -i $biotestdir/test.fas -x

