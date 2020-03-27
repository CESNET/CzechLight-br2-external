#!/bin/sh

set -ex

for candidate in osc oscW eth2; do
    if [[ -d "/sys/class/net/${candidate}" ]]; then
        NETDEV="${candidate}"
        break
    fi
done

if [[ ! -n "${NETDEV+set}" ]]; then
    echo "Unrecognized SFP device name"
    exit 1
fi

# SFP: green lit for "link"
# SFP: green blinking for activity
cd /sys/class/leds/sfp:green
echo netdev > trigger
echo "${NETDEV}" > device_name
echo 1 > link
echo 1 > rx
echo 1 > tx
