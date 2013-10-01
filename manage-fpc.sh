#!/bin/sh -eu

. ${_%/*}/lib.sh

function usage() { # {{{
  echo "Usage: " $(basename $0) "COMMAND boxname
        where COMMAND is one of:
          ssh      connect to boxname via ssh using its key
          shutdown shutdown boxname (has to be enabled in /etc/sudoers)
          pcaps    list currently stored pcaps on boxname
          status   print status information of boxname
          start    start tcpdump on boxname
          stop     stop tcpdump on boxname
        boxname name of the box to configure with boxname.conf
$(basename ${0%.sh}) version $version"; 
} # }}} 

if [ $# -lt 2 ]; then
  usage
  exit 1
fi

readconfig "${2}.conf"

if ! test -s ${2}.key; then
  key=init.key
else
  key=${2}.key
fi

if [ $1 == "ssh" ]; then
  #ssh -i $key ${LOGIN}@$IP
  remoteexec ""
fi

if [ $1 == "shutdown" ]; then
  remoteexec "sudo shutdown -h now"
fi

if [ $1 == "pcaps" ]; then
  echo current:
  remoteexec "find $BASE -maxdepth 1 -iname '*.pcap' -ls" || echo $BASE not found
  echo archived:
  remoteexec "test -d $BASE/archive && find $BASE/archive -iname '*.pcap' -ls" || true
  echo transfer in progress:
  remoteexec "test -d $BASE/archive && find $BASE/archive -iname '*.pcap.*' -ls" || true
fi

if [ $1 == "status" ]; then
  if [ $key == "init.key" ]; then
    echo -n using master key to login..
  else
    echo -n using $key to login..
  fi
  ssh -o PasswordAuthentication=no -i $key ${LOGIN}@$IP echo success
  echo -n "tcpdump is.."
  if remoteexec "pgrep -u $2 -o tcpdump > /dev/null"; then
    echo running
  else
    echo not running
  fi
  echo -n "crontabs are.."
  if remoteexec "crontab -l | grep -q sniff-fpc.sh" && remoteexec "crontab -l | grep -q pushpcap-fpc.sh"; then
    echo -n ""
  else
    echo -n "not "
  fi
  echo installed
fi

if [ $1 == "start" ]; then
  remoteexec "rm -f $BASE/stop"
  remoteexec "$BASE/sniff-fpc.sh \& disown" &
fi

if [ $1 == "stop" ]; then
  remoteexec "touch $BASE/stop"
  remoteexec "killall -q -s SIGINT tcpdump" || true
  remoteexec "find $BASE -maxdepth 1 -name '*pcap' -type f -exec mv '{}' $BASE/archive \;"
fi

