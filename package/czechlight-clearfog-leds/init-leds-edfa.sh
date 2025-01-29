#!/bin/sh

set -ex

# Green LED for "we're getting some signal"

if grep -q '\<czechlight=sdn-roadm-line\>' /proc/cmdline; then
    EDFA1_STAGE1_LED=line:green
elif grep -q '\<czechlight=sdn-inline\>' /proc/cmdline; then
    EDFA1_STAGE1_LED=line-west:green
    EDFA1_STAGE2_LED=line-east:green
elif \
        grep -q '\<czechlight=sdn-roadm-add-drop\>' /proc/cmdline || \
        grep -q '\<czechlight=sdn-roadm-coherent-a-d\>' /proc/cmdline || \
        grep -q '\<czechlight=sdn-roadm-hires-add-drop\>' /proc/cmdline \
        ; then
    EDFA1_STAGE1_LED=express:green
elif grep -q '\<czechlight=sdn-bidi-cplus1572\>' /proc/cmdline; then
    EDFA1_STAGE1_LED=line-c:green
    EDFA2_STAGE1_LED=line-l:green
else
    echo "No EDFA LEDs recognized"
    exit 1
fi

if [[ -n "${EDFA1_STAGE1_LED+set}" ]]; then
    cd /sys/class/leds/${EDFA1_STAGE1_LED}
    echo gpio > trigger
    GPIO=$(sed -En 's/.*gpio-(.*) \(EDFA1_ST1_IN_LOS_A .*/\1/p' /sys/kernel/debug/gpio)
    echo $GPIO > gpio
fi

if [[ -n "${EDFA1_STAGE2_LED+set}" ]]; then
    cd /sys/class/leds/${EDFA1_STAGE2_LED}
    echo gpio > trigger
    GPIO=$(sed -En 's/.*gpio-(.*) \(EDFA1_ST2_IN_LOS_A .*/\1/p' /sys/kernel/debug/gpio)
    echo $GPIO > gpio
fi

if [[ -n "${EDFA2_STAGE1_LED+set}" ]]; then
    cd /sys/class/leds/${EDFA2_STAGE1_LED}
    echo gpio > trigger
    GPIO=$(sed -En 's/.*gpio-(.*) \(EDFA2_ST1_IN_LOS_A .*/\1/p' /sys/kernel/debug/gpio)
    echo $GPIO > gpio
fi

# there's no EDFA2, stage2 in any of our HW, so no EDFA2_STAGE2_LED block here
