#!/usr/bin/env bash

testsdir=$(dirname $0)

datadir=$testsdir/../../bio/spec
spec=$datadir/gfa2/gfa2.complete.yaml
tests=$datadir/gfa2/gfa2.datatypes_tests.yaml

$testsdir/spec_tests_apibased.py $spec $tests
