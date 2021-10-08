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

