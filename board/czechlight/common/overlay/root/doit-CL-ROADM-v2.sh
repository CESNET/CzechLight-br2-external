#!/bin/bash

set -eux -o pipefail
shopt -s failglob

for DIR in /etc/yang-setup/*; do
	${DIR}/install-yang.sh
done

sysrepoctl --install --search-dir /usr/share/cla-sysrepo/yang --yang /usr/share/cla-sysrepo/yang/czechlight-roadm-v2.yang
sysrepocfg --datastore=startup --import=/usr/share/cla-sysrepo/yang/czechlight-roadm-v2.startup.xml czechlight-roadm-v2

echo 'cla-sysrepod --properties-log-level=5 --sr-bridge-log-level=5 --sysrepo-log-level=3 --driver=CL-ROADMv2 --port=/dev/ttyUSB0' >> ~/.ash_history
