#!/bin/sh -eu

mv known_hosts .ssh

sudo install -m 440 -o root -g root  sshd_config /etc/ssh
sudo install -m 755 -o root -g root  net-fpc.sh /usr/sbin

# after this step the fpc user is locked-down!
sudo install -m 440 -o root -g root  sudoers /etc/sudoers

echo removing myself. Bye.
rm -f extract-on-box.tar sudoers sshd_config net-fpc.sh run-on-box.sh 
