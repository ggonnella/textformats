#!/usr/bin/env bash
if [ "$1" == "" ]; then
  echo "Usage: $0 <path_to_yaml_spec>"
  exit 1
fi
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
TF_SPEC=$SCRIPTPATH/../cli/tf_spec
bn=$(dirname $1)/$(basename $1 .yaml)
echo "Compile the YAML specification: "
time ${TF_SPEC} compile -s $bn.yaml -o $bn.tfs
echo "Datatypes listing from YAML: "
time ${TF_SPEC} info -s $bn.yaml
echo "Datatypes listing from TFS:"
time ${TF_SPEC} info -s $bn.tfs
