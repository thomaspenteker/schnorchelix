#!/bin/sh -eu

SPATH=${_%/*}
. $SPATH/lib.sh

function usage() { # {{{
  echo "Usage: " $(basename $0) "boxname
        prepare a fresh image for schnorchelix usage using boxname.conf.
$(basename ${0%.sh}) version $version"; 
} # }}} 

if [ $# -lt 1 ]; then
  usage
  exit 1
fi

readconfig ${1}.conf

if [ -e ${1}.key ]; then
  echo You have to remove the existing key ${1}.key for the box first
  exit 1
fi

rm -f extract-on-box.tar
tar -cf extract-on-box.tar known_hosts sudoers sshd_config net-fpc.sh run-on-box.sh

masterkey="init.key"
key=$masterkey
rshell="ssh -F /dev/null -t -i"

pushfiles extract-on-box.tar
remoteexec "tar xf ./extract-on-box.tar"
remoteexec "chmod u+x run-on-box.sh; ./run-on-box.sh"

rm -f extract-on-box.tar

echo installing core program scripts and cron jobs
$SPATH/setup-fpc.sh install $1
