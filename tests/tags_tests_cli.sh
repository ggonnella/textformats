#!/usr/bin/env bash

testsdir=$(dirname $0)
scriptsdir=$testsdir/../scripts
datadir=$testsdir/../data
spec=$datadir/spec/tags.textformats.yaml
tests=$datadir/spec/tests/tags.yaml

cd $testsdir/../cli
#nim c textformats_cli
cd $testsdir/../tests
time ./spec_tests_clibased.py --preprocess $spec $tests
