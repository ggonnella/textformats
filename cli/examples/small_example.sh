#!/usr/bin/env bash

PATH=${PATH}:${PWD}/..

cigarsdir="../../benchmarks/data/cigars"
encoded="1M100D1I2M3M4M"
encoded_wrong="1M;100D1I2M3M4M"
decoded_json="[{\"length\":100,\"code\":\"M\"},"
decoded_json+="{\"length\":10,\"code\":\"D\"}]"

echo -n "Decoded value: "
tf_decode string -s $cigarsdir/cigars.yaml -t cigar_str -e $encoded
if [ $? -eq 0 ]; then
  echo "[Decoding succeeded]"
else echo Error code: $?; exit 1; fi

echo -n "Encoded value: "
tf_encode json -s $cigarsdir/cigars.yaml -t cigar_str -d $decoded_json
if [ $? -eq 0 ]; then
  echo "[Encoding succeeded]"
else echo Error code: $?; exit 1; fi

tf_decode string -s $cigarsdir/cigars.yaml -t cigar_str -e $encoded_wrong
if [ $? -ne 0 ]; then
  echo "[DecodingError as expected]"
else echo Error code: $?; exit 1; fi
