#!/usr/bin/env bash
echo "Preparing input data"
rm -f large.egc
touch large.egc
for i in {1..910}; do
  cat example.egc >> large.egc
done
echo
echo "EGC encoding and decoding test"
echo
echo "- TextFormats-based parser"
echo
#echo "(0) compile EGC specification"
#time tf_spec compile -s egc.yaml -o egc.tfs
#echo
echo "(1) decode EGC file to JSON file"
time ./egc2json.py large.egc egc.yaml > large.json
echo
echo "(2) write EGC file from JSON data"
time ./json2egc.py large.json egc.yaml > converted.egc
echo
echo "(3) compare output EGC file to input EGC file"
echo
diff -q large.egc converted.egc
if [ $? -eq 0 ]; then echo "No differences found."; fi
echo
echo "- Ad-hoc parser"
echo
echo "(1) decode EGC file to JSON file"
time ./egc2json_ad_hoc.py large.egc > large.json
echo
echo "(2) write EGC file from JSON data"
time ./json2egc_ad_hoc.py large.json > converted.egc
echo
echo "(3) compare output EGC file to input EGC file"
echo
diff -q large.egc converted.egc
if [ $? -eq 0 ]; then echo "No differences found."; fi
