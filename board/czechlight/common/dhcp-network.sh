#!/bin/bash

set -eux -o pipefail
shopt -s failglob

for IFACE in eth0 enp0s13 enp0s14; do
  cat <<EOF > ${TARGET_DIR}/usr/lib/systemd/network/${IFACE}.network
[Match]
Name=${IFACE}
[Network]
DHCP=yes
EOF
done
