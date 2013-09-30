#!/bin/sh -eu

. ./$(hostname).conf

BASE=${BASE:-$HOME}
data=${DATA:-/data/$(hostname)}

nice -n 19 gzip -5 $BASE/archive/*pcap || true
nice -n 19 rsync -a -p $BASE/archive/*.pcap.gz "$(hostname)"@"$SERVER":$data/
nice -n 19 rm -f $BASE/archive/*.pcap.gz
