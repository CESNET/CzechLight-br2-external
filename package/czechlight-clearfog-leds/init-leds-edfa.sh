#!/bin/sh

set -ex

# Green LED for "we're getting some signal"

if grep -q '\<czechlight=sdn-inline\>' /proc/cmdline; then
    # LEDs have different labels on this HW
    STAGE1_LED=uid:green
    STAGE2_LED=line:green
else
    # Line/Degree: signal present at Line IN
    # WSS A/D and Coherent A/D: signal present at some Express IN
    STAGE1_LED=line:green
fi

if [[ -n "${STAGE1_LED+set}" ]]; then
    cd /sys/class/leds/${STAGE1_LED}
    echo gpio > trigger
    GPIO=$(sed -En 's/.*gpio-(.*) \(EDFA1_ST1_IN_LOS_A .*/\1/p' /sys/kernel/debug/gpio)
    echo $GPIO > gpio
fi

if [[ -n "${STAGE2_LED+set}" ]]; then
    cd /sys/class/leds/${STAGE2_LED}
    echo gpio > trigger
    GPIO=$(sed -En 's/.*gpio-(.*) \(EDFA1_ST2_IN_LOS_A .*/\1/p' /sys/kernel/debug/gpio)
    echo $GPIO > gpio
fi
