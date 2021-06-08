#!/usr/bin/env bash

testsdir=$(dirname $0)
scriptsdir=$testsdir/../scripts
datadir=$testsdir/../data
validate=$scriptsdir/validate_datatypes_spec.py

$validate $datadir/spec_validation_schemas/datatypes.validation.yaml \
          $datadir/gfa2/gfa2.datatypes.yaml
$validate $datadir/spec_validation_schemas/datatypes_tests.validation.yaml \
          $datadir/gfa2/gfa2.datatypes_tests.yaml
