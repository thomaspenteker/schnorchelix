#!/bin/sh -eu

. ./$(hostname).conf

base=${base:-$HOME}

# are we allowed to run?
if test -f ${base}/stop || pgrep -u $LOGNAME -o tcpdump > /dev/null; then
  #echo Found running tcpdump, doing nothing. Goodbye.
  exit 0
fi

mv $base/*pcap $base/archive

sudo /usr/sbin/tcpdump -G 600 \
  -w $base/'%Y.%m.%d-%H:%M-'$(hostname).pcap \
	-i eth1 \
	-z $base/post-fpc.sh \
	-Z $LOGNAME \
	$FILTER

