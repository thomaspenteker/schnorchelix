#!/bin/sh -eu

BASE=${BASE:-$HOME}

if [ $# -lt 1 ]; then
  echo usage: $0 pcapfile
  exit 1
fi

if ! test -d $BASE/archive; then
  rm -rf $BASE/archive
  mkdir -p $BASE/archive
fi

find $BASE/*.pcap -maxdepth 1 -exec mv '{}' $BASE/archive \;
