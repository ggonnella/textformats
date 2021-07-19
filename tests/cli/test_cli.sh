#!/usr/bin/env bash
#
# Test TextFormats command line interface
#
# The same test is done with the Nim, C and Python API.
#

# reliable-way-for-a-bash-script-to-get-the-full-path-to-itself:
# https://stackoverflow.com/questions/4774054/
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
TESTDATA="$SCRIPTPATH/../testdata/api/"
CLI="$SCRIPTPATH/../../cli/"

YAML_SPEC="$TESTDATA/fasta.yaml"
PREPROC_SPEC="$TESTDATA/fasta.tfs"
BAD_YAML_SPEC="$TESTDATA/wrong_yaml_syntax.yaml"
NONEXISTING_SPEC="$TESTDATA/xyz.yaml"
TESTFILE="$TESTDATA/good_test.yaml"
BAD_TESTFILE="$TESTDATA/bad_test.yaml"

EXP_DATATYPES=("entry" "sequence" "default" "header" "sequence_line"
               "unit_for_tests" "file" "double_header_symbol_line" "line"
               "line_failing")

YAML_SPEC_INLINE="{\"datatypes\": {\"x\": {\"constant\": \"x\"}}}"
BAD_YAML_SPEC_INLINE="{\"datatypes\": {\"x\": []}}"
TESTDATA_INLINE="{\"testdata\": {\"x\": {\"valid\": [\"x\"], \"invalid\": [\"y\"]}}}"
BAD_TESTDATA_INLINE="{\"testdata\": {\"x\": {\"valid\": [\"y\"]}}}"
YAML_SPEC_INLINE_DT="x"
read -r -d "" YAML_SPEC_INLINE_DT_REPR <<-'EOF'
x:
  constant: "x"
EOF
read -r -d "" YAML_SPEC_INLINE_DT_STR <<-'EOF'
Datatype: 'x': constant value

  the constant value is string:"x"

- regular expression:
    regex which has been generated for the data type:
      'x'
    a match ensures validity of the encoded string
EOF

DATA_TYPE="header"
NONEXISTING_DATA_TYPE="heder"

DATA_E=">ABCD some sequence"
BAD_DATA_E="ABCD some sequence"
DATA_D="{\"fastaid\":\"ABCD\",\"desc\":\"some sequence\"}"
BAD_DATA_D="{\"desc\":\"some sequence\"}"

DATAFILE="$TESTDATA/test.fas"
DATA_TYPE_SCOPE_LINE="line"
BAD_DATA_TYPE_SCOPE_LINE="line_failing"
DATA_TYPE_SCOPE_UNIT="unit_for_tests"
DATA_TYPE_SCOPE_SECTION="entry"
DATA_TYPE_SCOPE_FILE="file"

function __do_check { local test=$1 lbl=$2 lineno=$3 err=$4 cmd=$5 cmdout=$6
  if test $test -eq 0; then
    echo "[OK] $lbl"
  else
    echo -e "[ERROR] $lbl (Line $lineno): $err"
    echo "Command output/error:"
    echo "$cmdout" | sed 's/^/  /'
    echo "Command:"
    echo "$cmd" | sed 's/^/  /'
    exit 1
  fi
}

function check_ok { local lineno=$1 lbl=$2 cmd=$3
  local cmdout
  cmdout="$(eval $cmd 2>&1)"
  __do_check $? "$lbl" "$lineno" "Unexpected error (code $?)" "$cmd" "$cmdout"
}

function check_fails { local lineno=$1 lbl=$2 cmd=$3
  local cmdout
  cmdout="$(eval $cmd 2>&1)"
  test $? -ne 0
  __do_check $? "$lbl" "$lineno" "Unexpected success" "$cmd" "$cmdout"
}

function check_output_eq { local lineno=$1 lbl=$2 cmd=$3 expected=$4
  local cmdout
  cmdout="$(eval $cmd 2>&1)"
  errmsg="Unexpected output\nExpected: ${expected}\n"
  test "${cmdout}" == "${expected}"
  __do_check $? "$lbl" "$lineno" "$errmsg" "$cmd" "${cmdout}"
}

function check_output_unordered_eq { local lineno=$1; shift
                                     local lbl=$1; shift
                                     local cmd=$1; shift
                                     local expected=($@)
  local cmdout
  cmdout="$(eval $cmd 2>&1 | sort)"
  IFS=$'\n'
  local -a found
  read -r -d '' -a found <<<"$cmdout"
  expected=($(sort <<<"${expected[*]}"))
  unset IFS
  expected="${expected[*]}"
  found="${found[*]}"
  errmsg="Unexpected output\nExpected (in any order): $expected\n"
  test "${found}" == "${expected}"
  __do_check $? "$lbl" "$lineno" "$errmsg" "$cmd" "${found}"
}

function test_specification_loading {
  check_fails $LINENO "load spec string with syntax err" \
    "echo $BAD_YAML_SPEC_INLINE | ${CLI}tf_spec info"
  check_ok $LINENO "load valid spec string" \
    "echo ${YAML_SPEC_INLINE} | ${CLI}tf_spec info"
  check_fails $LINENO "load spec YAML file with syntax err" \
    "${CLI}tf_spec info -s $BAD_YAML_SPEC"
  check_fails $LINENO "load non-existing spec file" \
    "${CLI}tf_spec info -s $NONEXISTING_SPEC"
  check_ok $LINENO "load valid YAML spec file" \
    "${CLI}tf_spec info -s $YAML_SPEC"
}

function test_specification_preprocessing {
  check_ok $LINENO "preprocess specification" \
    "${CLI}tf_spec preprocess -s $YAML_SPEC -o $PREPROC_SPEC"
}

function test_specification_tests {
  check_ok $LINENO "run YAML specification succeeding tests" \
    "${CLI}tf_spec test -s $YAML_SPEC -f $TESTFILE"
  check_fails $LINENO "run YAML specification failing tests" \
    "${CLI}tf_spec test -s $YAML_SPEC -f $BAD_TESTFILE"
  check_ok $LINENO "run preproc specification succeeding tests" \
    "${CLI}tf_spec test -s $PREPROC_SPEC -f $TESTFILE"
  check_fails $LINENO "run preproc specification failing tests" \
    "${CLI}tf_spec test -s $PREPROC_SPEC -f $BAD_TESTFILE"
  tmpfile=$(mktemp)
  echo $BAD_TESTDATA_INLINE > $tmpfile
  check_fails $LINENO "run failing tests from string" \
    "echo $YAML_SPEC_INLINE | ${CLI}tf_spec test -f $tmpfile"
  echo $TESTDATA_INLINE > $tmpfile
  check_ok $LINENO "run succeeding tests from string" \
    "echo $YAML_SPEC_INLINE | ${CLI}tf_spec test -f $tmpfile"
  rm $tmpfile
}

function test_specification_list_datatypes {
  check_output_unordered_eq $LINENO "list spec datatypes" \
    "${CLI}tf_spec info -s $YAML_SPEC" \
    "${EXP_DATATYPES[@]}"
}

function test_datatype_definition_loading {
  check_fails $LINENO "load non-existing datatype definition" \
    "${CLI}tf_spec info -s $YAML_SPEC -t $NONEXISTING_DATA_TYPE"
  check_ok $LINENO "load existing datatype definition" \
    "${CLI}tf_spec info -s $YAML_SPEC -t $DATA_TYPE"
}

function test_datatype_definition_desc {
  check_output_eq $LINENO "verbose description of datatype definition" \
    "echo $YAML_SPEC_INLINE | ${CLI}tf_spec info -t $YAML_SPEC_INLINE_DT" \
    "$YAML_SPEC_INLINE_DT_STR"
  check_output_eq $LINENO "repr of datatype definition" \
    "echo $YAML_SPEC_INLINE | ${CLI}tf_spec info -k repr -t $YAML_SPEC_INLINE_DT" \
    "$YAML_SPEC_INLINE_DT_REPR"
}

function test_handling_encoded_strings {
  check_fails $LINENO "decode wrong text representation" \
    "${CLI}tf_decode string -s $YAML_SPEC -t $DATA_TYPE -e '$BAD_DATA_E'"
  check_output_eq $LINENO "decode valid text representation" \
    "${CLI}tf_decode string -s $YAML_SPEC -t $DATA_TYPE -e '$DATA_E'" \
    "$DATA_D"
  check_fails $LINENO "validate wrong text representation" \
    "${CLI}tf_validate encoded -s $YAML_SPEC -t $DATA_TYPE -e '$BAD_DATA_E'"
  check_ok $LINENO "validate valid text representation" \
    "${CLI}tf_validate encoded -s $YAML_SPEC -t $DATA_TYPE -e '$DATA_E'"
}

function test_handling_decoded_data {
  check_fails $LINENO "encode wrong data" \
    "${CLI}tf_encode json -s $YAML_SPEC -t $DATA_TYPE -d '$BAD_DATA_D'"
  check_output_eq $LINENO "encode valid data" \
    "${CLI}tf_encode json -s $YAML_SPEC -t $DATA_TYPE -d '$DATA_D'" \
    "$DATA_E"
  check_fails $LINENO "validate wrong data" \
    "${CLI}tf_validate decoded -s $YAML_SPEC -t $DATA_TYPE -d '$BAD_DATA_D'"
  check_ok $LINENO "validate valid data" \
    "${CLI}tf_validate decoded -s $YAML_SPEC -t $DATA_TYPE -d '$DATA_D'"
}

function test_file_decoding {
  check_fails $LINENO "decode file, scope: undef" \
    "${CLI}tf_decode file -i $DATAFILE -s $YAML_SPEC -t $DATA_TYPE_SCOPE_LINE"
  check_fails $LINENO "decode file, scope: line, wrong def" \
    "${CLI}tf_decode file -i $DATAFILE -s $YAML_SPEC -t $BAD_DATA_TYPE_SCOPE_LINE --scope line"
  check_ok $LINENO "decode file, scope: line, correct def" \
    "${CLI}tf_decode file -i $DATAFILE -s $YAML_SPEC -t $DATA_TYPE_SCOPE_LINE --scope line"
  check_ok $LINENO "decode file, scope: line, correct def, wrapped" \
    "${CLI}tf_decode file -i $DATAFILE -s $YAML_SPEC -t $DATA_TYPE_SCOPE_LINE --scope line --wrapped"
  check_fails $LINENO "decode file, scope: unit, wrong unitsize" \
    "${CLI}tf_decode file -i $DATAFILE -s $YAML_SPEC -t $DATA_TYPE_SCOPE_UNIT"
  check_ok $LINENO "decode file, scope: unit, unitsize 4" \
    "${CLI}tf_decode file -i $DATAFILE -s $YAML_SPEC -t $DATA_TYPE_SCOPE_UNIT --unitsize 4"
  check_ok $LINENO "decode file, scope: section" \
    "${CLI}tf_decode file -i $DATAFILE -s $YAML_SPEC -t $DATA_TYPE_SCOPE_SECTION"
  check_ok $LINENO "decode file, scope: section, splitted" \
    "${CLI}tf_decode file -i $DATAFILE -s $YAML_SPEC -t $DATA_TYPE_SCOPE_SECTION --splitted"
  check_ok $LINENO "decode file, scope: file" \
    "${CLI}tf_decode file -i $DATAFILE -s $YAML_SPEC -t $DATA_TYPE_SCOPE_FILE"
  check_ok $LINENO "decode file, scope: file, splitted" \
    "${CLI}tf_decode file -i $DATAFILE -s $YAML_SPEC -t $DATA_TYPE_SCOPE_FILE --splitted"
  check_ok $LINENO "decode file, scope: file, embedded" \
    "${CLI}tf_decode file -i $YAML_SPEC -t $DATA_TYPE_SCOPE_FILE"
}

test_specification_loading
test_specification_preprocessing
test_specification_tests
test_specification_list_datatypes
test_datatype_definition_loading
test_datatype_definition_desc
test_handling_encoded_strings
test_handling_decoded_data
test_file_decoding
