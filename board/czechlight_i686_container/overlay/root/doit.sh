#!/bin/sh
set -ex
/etc/yang-setup/01-*/install-yang.sh
/etc/yang-setup/02-*/install-yang.sh
/etc/yang-setup/03-*/install-yang.sh
sysrepoctl --install --yang /usr/share/cla-sysrepo/yang/dummy-amp.yang
systemctl start sysrepod
systemctl start sysrepo-plugind
netopeer2-server -v2
cla-sysrepod --module dummy-amp --toplevel amplifier --sr-bridge-log-level 5 --properties-log-level 5 --static-properties /usr/share/cla-sysrepo/static-data/dummy-amp.static.data
