#!/bin/sh -eu

base=${base:-$HOME}

if [ $# -lt 1 ]; then
  echo usage: $0 pcapfile
  exit 1
fi

if ! test -d $base/archive; then
  rm -rf $base/archive
  mkdir -p $base/archive
fi

mv $base/*.pcap $base/archive
