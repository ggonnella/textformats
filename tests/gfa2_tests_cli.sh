#!/usr/bin/env bash

testsdir=$(dirname $0)
scriptsdir=$testsdir/../scripts
datadir=$testsdir/../bio/spec
spec=$datadir/gfa2/gfa2.with_generic_tags.yaml
tests=$datadir/gfa2/gfa2.datatypes_tests.yaml

cd $testsdir/../tests
echo $PWD
time ./spec_tests_clibased.py --preprocess $spec $tests
