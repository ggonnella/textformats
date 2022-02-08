#!/usr/bin/env bash
echo "EGC encoding and decoding test"
echo
echo "- TextFormats-based parser"
echo "(1) decode EGC file to JSON file"
time ./egc2json.py example.egc egc.yaml > example.json
echo "(2) write EGC file from JSON data"
time ./json2egc.py example.json egc.yaml > converted.egc
echo "(3) compare output EGC file to input EGC file"
diff -q example.egc converted.egc
if [ $0 -eq 0 ]; then echo "No differences found."; fi
echo
echo "- Ad-hoc parser"
echo "(1) decode EGC file to JSON file"
time ./egc2json_ad_hoc.py example.egc > example.json
echo "(2) write EGC file from JSON data"
time ./json2egc_ad_hoc.py example.json > converted.egc
echo "(3) compare output EGC file to input EGC file"
diff -q example.egc converted.egc
if [ $0 -eq 0 ]; then echo "No differences found."; fi
