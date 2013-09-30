#!/bin/bash -eu

PATH=/sbin:/usr/sbin:/bin:/usr/bin

if [ $# -lt 4 ]; then
  echo usage: $0 IP Netmask Gateway Hostname
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

valid_host() {
  if [[ $1 =~ ^[a-zA-Z0-9][a-zA-Z0-9]*$ ]]; then
    return 0
  else
    return 1
  fi
}

if ! valid_ip $1 || ! valid_ip $2 || ! valid_ip $3; then
  exit 1
fi

if ! valid_host $4; then
  exit 1
fi

# point of no return
trap '' SIGINT 2> /dev/null || trap ''  INT

echo "$4" > /etc/hostname
hostname "$4"
sed -i '1d' /etc/hosts
sed -i 1i127.0.0.1\ localhost\ "$4" /etc/hosts

f=$(mktemp)

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

start networking > /dev/null
