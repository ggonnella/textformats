#!/usr/bin/env bash

testsdir=$(dirname $0)
scriptsdir=$testsdir/../scripts
datadir=$testsdir/../bio/spec
spec=$datadir/tags.spec.yaml
tests=$datadir/tests/tags.yaml

cd $testsdir/../tests
time ./spec_tests_clibased.py --preprocess $spec $tests
