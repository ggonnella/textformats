#!/usr/bin/env bash

testsdir=$(dirname $0)

datadir=$testsdir/../../spec
spec=$datadir/gfa/gfa2.yaml
tests=$datadir/gfa/gfa2.yaml

$testsdir/spec_tests_apibased.py $spec $tests
