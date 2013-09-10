#!/bin/sh -eu

. ./$(hostname).conf

base=${base:-$HOME}
data=${DATA:-/data/$(hostname)}

nice -n 19 gzip -5 $base/archive/*pcap || true
nice -n 19 rsync -a -p $base/archive/*.pcap.gz "$(hostname)"@"$SERVER":$data/
nice -n 19 rm -f $base/archive/*.pcap.gz
