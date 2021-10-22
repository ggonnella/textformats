#!/usr/bin/env bash
inputdir="../../benchmarks/data/cigars/"
inputfn="100k_cigars_len100"
input="$inputdir/$inputfn"
if [ ! -e $input ]; then
  cd $inputdir
  make $inputfn
  cd -
fi
for bm in \
  split_and_namecapt_nregex \
  split_and_namecapt_nre    \
  split_and_namecapt_regex  \
  split_and_namecapt_python_re \
  split_and_namecapt_python_nimporter_regex \
  split_and_numcapt_nregex  \
  split_and_numcapt_nre     \
  split_and_numcapt_regex   \
  split_and_numcapt_re      \
  split_and_numcapt_re_static_types \
  split_and_numcapt_python_re \
  split_and_validate_nregex  \
  split_and_validate_nre     \
  split_and_validate_regex   \
  split_and_validate_re      \
  split_and_validate_python_re \
  validate_nregex            \
  validate_nre               \
  validate_regex             \
  validate_re                \
  validate_python_re; do
  echo run ${bm} ...
  time ./${bm} -i $input
  echo "-------"
  echo
done
