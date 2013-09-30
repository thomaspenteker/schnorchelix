#!/bin/sh -eu

. ./$(hostname).conf

BASE=${BASE:-$HOME}

# are we allowed to run?
if test -f ${BASE}/stop || pgrep -u $LOGNAME -o tcpdump > /dev/null; then
  #echo Found running tcpdump, doing nothing. Goodbye.
  exit 0
fi

find $BASE -maxdepth 1 -name '*pcap' -type f -exec mv '{}' $BASE/archive \;

sudo /usr/sbin/tcpdump -G 600 \
  -w $BASE/'%Y.%m.%d-%H:%M-'$(hostname).pcap \
	-i ${IF:-eth0} \
	-z $BASE/post-fpc.sh \
	-Z $LOGNAME \
	$FILTER

