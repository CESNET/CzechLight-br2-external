#!/bin/sh

set -ex

# SFP: green lit for "link"
# SFP: green blinking for activity

cd /sys/class/leds/sfp:green
for NETDEV in osc oscW eth2; do
    if [[ -d /sys/class/net/$NETDEV ]]; then
        echo $NETDEV > device_name
        break
    fi
done
