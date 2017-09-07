#!/bin/bash

set -eux -o pipefail
shopt -s failglob

mount / -o remount,rw
mv /etc/sysrepo /etc/sysrepo.orig
mkdir /etc/sysrepo
chmod 000 /etc/sysrepo
mke2fs -t ext4 -F -F -q /dev/sda2
echo '/dev/sda2 /etc/sysrepo ext4 defaults 0 0' >> /etc/fstab
mount -a
mv /etc/sysrepo.orig/* /etc/sysrepo/
rmdir /etc/sysrepo.orig

# some of these need r/w rootfs due to SSH keys
for DIR in /etc/yang-setup/*; do
	${DIR}/install-yang.sh
done

mount / -o remount,ro

sysrepoctl --install --search-dir /usr/share/cla-sysrepo/yang --yang /usr/share/cla-sysrepo/yang/czechlight-roadm-v2.yang
sysrepocfg --datastore=startup --import=/usr/share/cla-sysrepo/yang/czechlight-roadm-v2.startup.xml czechlight-roadm-v2

systemctl start czechlight-roadm-v2
systemctl start netopeer2-server

mount / -o remount,rw
systemctl enable czechlight-roadm-v2
systemctl enable netopeer2-server
echo 'cla-sysrepod --properties-log-level=5 --sr-bridge-log-level=5 --sysrepo-log-level=3 --driver=CL-ROADMv2 --port=/dev/ttyUSB0' >> ~/.ash_history
mount / -o remount,ro
