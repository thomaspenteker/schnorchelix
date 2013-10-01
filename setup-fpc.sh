#!/bin/sh -eu

. ${_%/*}/lib.sh
# copy $@ to $IP:$BASE
pushfiles() { # {{{
  #echo key: ${masterkey:-$KEY}
  #echo rsync -rp -e "$rshell ${masterkey:-$KEY}" $@ ${LOGIN}@$IP:$BASE
  rsync -rp -e "$rshell ${masterkey:-$KEY}" $@ ${LOGIN}@$IP:$BASE
} # }}}

# $1 command and params to execute
remoteexec() { # {{{
  # try to avoid ControlPersistent settings, see pushnetconfig for details
  $rshell ${masterkey:-$KEY} ${LOGIN}@$IP "$1"
} # }}}

function usage() { # {{{
  echo "Usage: " $(basename $0) "COMMAND boxname [OPTION]
        where COMMAND is one of:
          install   copy new key, configuration and scripts to a PREPARED box
                    (user install-fpc.sh for that)
          newconfig push a new config and restart packet capturing
          newkey    replace the current SSH key on a box
          start     start packet capture on a box
          stop      stop packet capture on a box
        boxname name of the box to configure with boxname.conf
        [OPTION] may be a combination of:
        [-n] don't push network settings
        [-k] don't push a new key
        [-o IP] can be used to specify the current IP address of a box for the
                install commmand (instead of the one from boxname.conf)
              
$(basename ${0%.sh}) version $version"; 
} # }}} 

getoptions() { # {{{
  if [ $# -lt 2 ]; then
    usage
    exit 0
  fi
  case $1 in 
    install|newkey|newconfig|start|stop) mode=$1 shift 1 ;;
    *) usage; exit 1 ;;
  esac

  config=${1}.conf
  shift 1

  while getopts knho: option; do
    case $option in
      "n") export nonet="1" ;;
      "k") export nokey="1" ;;
      "o") export currip=$OPTARG ;;
      #"p") p1[$((${#p1[@]}+1))]=$OPTARG ;; # collect patches
      [?]|"h") usage; exit 0 ;;
    esac
  done
} # }}}

checkenv() { # {{{
  if ! test -s $config; then 
    eecho "cannot read from config"
    return 1
  fi
  test -z $SERVER && eecho "server not configured" && return 1
  test -z $IP && eecho "ip address not configured" && return 1
  test -z $MODE && eecho "mode not configured" && return 1
  return 0
} # }}}

eecho() { # {{{
  echo $@ >&2
} # }}}

# push a new key to $IP, use our master key if necessary
pushkey() { # {{{
  # use master key to push our new key
  # replace it afterwards on the node
  if ! test -s $KEY; then
    masterkey="init.key"
  # replace key
  else
    mv $KEY ${KEY}.old
    masterkey=${KEY}.old
  fi
  genkey $KEY

  pushfiles $KEY ${KEY}.pub $config || (pushkey_failed; exit 1)
  remoteexec "mkdir -p $BASE/.ssh"
  remoteexec "mv $KEY .ssh/id_rsa"
  remoteexec "mv ${KEY}.pub .ssh/authorized_keys"
  masterkey=""
} # }}}

pushkey_failed() { # {{{
  echo failure pushing
  # TODO oder, falls existierend alten Key wiederherstellen
  rm $KEY ${KEY}.pub
} # }}}

# beware.
remotedel() { # {{{
  remoteexec "rm -rf $@"
} # }}} 

# assumption: this is only necessary if the box was not setup up with the
# default user. This creates the necessary user (default: fpc, LOGIN in
# $host.conf) on the box.
checkcreateuser() { # {{{
  remoteexec "useradd -d $BASE -s /usr/sbin/nologin -m $LOGIN 2>&1 | grep -v already\ exists"  || true
} # }}}

checkcreatelocaluser() { # {{{
  if [ $EUID != 0 ] ;then
    cmdpre=sudo
    echo possibly prompting for local sudo password:
  fi
  $cmdpre groupadd $sftpgroup 2>&1 | grep -v already\ exists || true
  $cmdpre useradd -b $data -m -g $sftpgroup $box 2>&1 | grep -v already\ exists || true
  if [ ! ${nokey:-0} = 1 ]; then
    $cmdpre install -d -m 755 ${data}/${box}/.ssh
    #echo $cmdpre install -m 400 -o $box ${KEY}.pub ${data}/${box}/.ssh/authorized_keys
    $cmdpre install -m 400 -o $box ${KEY}.pub ${data}/${box}/.ssh/authorized_keys
    rm ${KEY}.pub
  fi
} # }}}

# push a new network configuration and restart interfaces
pushnetconfig() { # {{{
  pushfiles $config
  # make sure the conneciton exits otherwise (in case of ControlPersistent in
  # ssh it will hang for quite some time!
  remoteexec "sudo /usr/sbin/net-fpc.sh $newip $NM $GW ${config%.conf} \&" &
  IP=$newip
} # }}}

installfiles() { # {{{
  pushfiles $config 
  pushfiles post-fpc.sh pushpcap-fpc.sh sniff-fpc.sh known_hosts
  remoteexec "mkdir -p .ssh"
  remoteexec "mv known_hosts .ssh"
  remoteexec "sed -i 1a\cd\ $BASE $BASE/sniff-fpc.sh"
  remoteexec "mkdir -p $BASE/archive"
  remoteexec "crontab -r 2>&1 | grep -v no\ crontab || true"
  remoteexec "echo -e '*/1 * * * * $BASE/sniff-fpc.sh\n*/10 * * * * $BASE/pushpcap-fpc.sh' | crontab -"
} # }}}

install() { # {{{
  if [ ! ${nokey:-0} = 1 ]; then
    echo -n pushing new key..  
    pushkey
    echo
  fi

  checkcreatelocaluser

  if [ ! ${nonet:-0} = 1 ]; then
    echo -n pushing network configuration.. 
    pushnetconfig
    echo
  fi
  checkcreateuser
  echo -n pushing config and scripts..
  installfiles
  remoteexec "killall -q -s SIGINT tcpdump" || true
  echo
} # }}}

newkey() { # {{{
  echo -n pushing new key..  
  pushkey
  checkcreatelocaluser
  echo
} # }}}

# TODO make sure ssh exits immediately after starting sniff-fpc.sh!
start() { # {{{
  remoteexec "rm -f $BASE/stop"
  remoteexec "./sniff-fpc.sh \&" &
} # }}}

stop() { # {{{
  remoteexec "touch $BASE/stop"
  remoteexec "killall -q -s SIGINT tcpdump" || true &
} # }}}

newconfig() { # {{{
  echo -n pushing new config..  
  pushfiles $config 
  echo
  stop
  start
} # }}}


main() {
# always call this to make sure LOGIN, IP and KEY are filled with sane values
readconfig $config || exit 1
checkenv || exit 1

eval $mode

}

getoptions $@
main
