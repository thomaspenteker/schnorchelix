#!/bin/sh -eu

version=0.1

function usage() { # {{{
  echo "Usage: " $(basename $0) "COMMAND boxname
        where COMMAND is one of:
          ssh      connect to boxname via ssh using its key
          shutdown shutdown boxname
          pcaps    list currently stored pcaps on boxname
          status   print status information of boxname
        boxname name of the box to configure with boxname.conf
$(basename ${0%.sh}) version $version"; 
} # }}} 

if [ $# -lt 2 ]; then
  usage
  exit 1
fi

. ./${2}.conf
export BASE=${BASE:-/home/${2}}
export LOGIN=${LOGIN:-fpc}


if ! test -s ${2}.key; then
  key=init.key
else
  key=${2}.key
fi

if [ $1 == "ssh" ]; then
  ssh -i $key ${LOGIN}@$IP
fi

if [ $1 == "shutdown" ]; then
  ssh -i $key ${LOGIN}@$IP "sudo shutdown -h now"
fi

if [ $1 == "pcaps" ]; then
  echo current:
  ssh -F /dev/null -i $key ${LOGIN}@$IP "find $BASE -maxdepth 1 -iname '*.pcap' -ls" || echo $BASE not found
  echo archived:
  ssh -F /dev/null -i $key ${LOGIN}@$IP "test -d $BASE/archive && find $BASE/archive -iname '*.pcap' -ls" || true
  echo transfer in progress:
  ssh -F /dev/null -i $key ${LOGIN}@$IP "test -d $BASE/archive && find $BASE/archive -iname '*.pcap.*' -ls" || true
fi

if [ $1 == "status" ]; then
  if [ $key == "init.key" ]; then
    echo -n using master key to login..
  else
    echo -n using $key to login..
  fi
  ssh -o PasswordAuthentication=no -i $key ${LOGIN}@$IP echo success
  echo -n "tcpdump is.."
  if ssh -i $key ${LOGIN}@$IP "pgrep -u $2 -o tcpdump > /dev/null"; then
    echo running
  else
    echo not running
  fi
fi
