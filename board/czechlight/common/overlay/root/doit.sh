#!/bin/bash

set -eux -o pipefail
shopt -s failglob

for DIR in /etc/yang-setup/*; do
	${DIR}/install-yang.sh
done
for YANG in /usr/share/cla-sysrepo/yang/*.yang; do
	sysrepoctl --install --yang ${YANG}
done

screen -d -m -S s1
screen -S s1 -X screen 1 sysrepod -d -l3
sleep 1
screen -S s1 -X screen 2 sysrepo-plugind -d -l3
screen -S s1 -X screen 3 netopeer2-server -d -v2
screen -S s1 -X screen 4 cla-sysrepod --module dummy-amp --toplevel amplifier --static-properties /usr/share/cla-sysrepo/static-data/dummy-amp-notifications.static.data --properties-log-level 5 --sr-bridge-log-level 5
screen -dr -S s1
