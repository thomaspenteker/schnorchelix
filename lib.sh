#!/bin/sh -eu

version=0.1
rshell="ssh -F /dev/null -i"
sftpgroup="fpc"
# Directory that collects the boxes' PCAP files
data=/data

# $1 command and params to execute
remoteexec() { # {{{
  # try to avoid ControlPersistent settings, see pushnetconfig for details
  $rshell $key ${LOGIN}@$IP "$1"
} # }}}

# copy $@ to $IP:$BASE
pushfiles() { # {{{
  #echo key: ${masterkey:-$KEY}
  #echo rsync -rp -e "$rshell ${masterkey:-$KEY}" $@ ${LOGIN}@$IP:$BASE
  rsync -rp -e "$rshell ${masterkey:-$KEY}" $@ ${LOGIN}@${IP}:${BASE}
} # }}}

readconfig() { # {{{
  . ./$1
  export KEY=${1%.conf}.key
  export LOGIN=${LOGIN:-fpc}
  export BASE=${BASE:-/home/${LOGIN}}
  export box=${1%.conf}
  export newip=$IP
  # optionally overwrite with an optional IP
  export IP=${currip:-$IP}
} # }}}

# create a new public/private key pair $1{,.pub}
genkey() { # {{{
  # create key without a passphrase, change if you like
  ssh-keygen -q -t rsa -b 2048 -f $1 -P ''
} # }}}
