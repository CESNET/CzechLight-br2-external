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
    # west-to-east input, C-band
    EDFA1_STAGE1_LED=line-c:green
    # east-to-west input, C-band
    EDFA1_STAGE2_LED=line-c:blue
    # west-to-east input, L-band
    EDFA2_STAGE1_LED=line-l:green
    # east-to-west input, L-band
    EDFA2_STAGE2_LED=line-l:blue

    # FIXME: this might need some more clever heuristics, but so far all the bidi modules are active-highe,
    # while the older, dual-stage ones are active-low. Maybe it depends on FW version, though?
    EDFA_GPIO_ALARM_ACTIVE_HIGH=1
else
    echo "No EDFA LEDs recognized"
    exit 1
fi

if [[ -n "${EDFA1_STAGE1_LED+set}" ]]; then
    cd /sys/class/leds/${EDFA1_STAGE1_LED}
    echo gpio > trigger
    GPIO=$(sed -En 's/.*gpio-(.*) \(EDFA1_ST1_IN_LOS_A .*/\1/p' /sys/kernel/debug/gpio)
    echo $GPIO > gpio
    if [[ -n "${EDFA_GPIO_ALARM_ACTIVE_HIGH+set}" ]]; then
        echo 1 > inverted
    fi
fi

if [[ -n "${EDFA1_STAGE2_LED+set}" ]]; then
    cd /sys/class/leds/${EDFA1_STAGE2_LED}
    echo gpio > trigger
    GPIO=$(sed -En 's/.*gpio-(.*) \(EDFA1_ST2_IN_LOS_A .*/\1/p' /sys/kernel/debug/gpio)
    echo $GPIO > gpio
    if [[ -n "${EDFA_GPIO_ALARM_ACTIVE_HIGH+set}" ]]; then
        echo 1 > inverted
    fi
fi

if [[ -n "${EDFA2_STAGE1_LED+set}" ]]; then
    cd /sys/class/leds/${EDFA2_STAGE1_LED}
    echo gpio > trigger
    GPIO=$(sed -En 's/.*gpio-(.*) \(EDFA2_ST1_IN_LOS_A .*/\1/p' /sys/kernel/debug/gpio)
    echo $GPIO > gpio
    if [[ -n "${EDFA_GPIO_ALARM_ACTIVE_HIGH+set}" ]]; then
        echo 1 > inverted
    fi
fi

if [[ -n "${EDFA2_STAGE2_LED+set}" ]]; then
    cd /sys/class/leds/${EDFA2_STAGE2_LED}
    echo gpio > trigger
    GPIO=$(sed -En 's/.*gpio-(.*) \(EDFA2_ST2_IN_LOS_A .*/\1/p' /sys/kernel/debug/gpio)
    echo $GPIO > gpio
    if [[ -n "${EDFA_GPIO_ALARM_ACTIVE_HIGH+set}" ]]; then
        echo 1 > inverted
    fi
fi
