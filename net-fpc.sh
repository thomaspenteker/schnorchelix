#!/bin/bash -eu

if [ $# -lt 3 ]; then
  echo usage: $0 IP Netmask Gateway
  exit 1
fi

valid_ip() {
  if [[ $1 =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
    OIFS=$IFS
    IFS='.' ip=($1)
    IFS=$OIFS
    [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
    return $?
  fi
  return 1
}

if ! valid_ip $1 || ! valid_ip $2 || ! valid_ip $3; then
  exit 1
fi

# point of no return
trap '' SIGINT 2> /dev/null || trap ''  INT

f=$(/usr/bin/mktemp)

# adjust to your needs
/bin/cat > $f << EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet static
address $1
netmask $2
#network 192.168.1.0
#broadcast 192.168.56.255
gateway $3
dns-nameservers 8.8.8.8

auto eth2
iface eth2 inet dhcp

EOF

# stop networking did not work. WHATEVER.
/etc/init.d/networking stop > /dev/null

mv $f /etc/network/interfaces

/usr/sbin/start networking > /dev/null
