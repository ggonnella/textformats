#!/usr/bin/env bash

testsdir=$(dirname $0)

datadir=$testsdir/../../data
spec=$datadir/gfa2/tags.datatypes.yaml
tests=$datadir/gfa2/tags.datatypes_tests.yaml

$testsdir/spec_tests_apibased.py $spec $tests
