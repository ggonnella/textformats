#!/usr/bin/env bash
#
# Purpose: Try to find the directory containing nimbase.h
#
# Exit code:
#   0: success (location of directory is printed)
#   1: choosenim is used, nimbase.h not found
#   2: choosenim is not used, nimbase.h not found


which choosenim > /dev/null
if [ $? == 0 ]; then
  NIMVER=$(nim --version | grep -P -o "(?<=Version )\S+")
  NIMLIB=$HOME/.choosenim/toolchains/nim-${NIMVER}/lib
  if [ -e $NIMLIB/nimbase.h ]; then
    echo $NIMLIB
  else
    exit 1
  fi
else
  NIMBIN=$(which nim)
  NIMBIN_DEREF=$(readlink -f $NIMBIN)
  NIMBINDIR=$(dirname $NIMBIN_DEREF)
  NIMLIB=$NIMBINDIR/../lib
  if [ -e $NIMLIB/nimbase.h ]; then
    echo $NIMLIB
  else
    exit 1
  fi
fi
