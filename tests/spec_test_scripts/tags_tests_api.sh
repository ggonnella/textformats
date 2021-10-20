#!/usr/bin/env bash

testsdir=$(dirname $0)

datadir=$testsdir/../../spec
spec=$datadir/gfa/gfa.tags.yaml
tests=$datadir/tests/tags.yaml

$testsdir/spec_tests_apibased.py $spec $tests
