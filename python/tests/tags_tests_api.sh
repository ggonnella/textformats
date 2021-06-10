#!/usr/bin/env bash

testsdir=$(dirname $0)

datadir=$testsdir/../../bio/spec
spec=$datadir/tags.spec.yaml
tests=$datadir/tests/tags.yaml

$testsdir/spec_tests_apibased.py $spec $tests
