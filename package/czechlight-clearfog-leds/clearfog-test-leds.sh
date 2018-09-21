#!/bin/bash

LEDS=(NONE status:{red,green,blue} uid:{red,green,blue} line:{red,green,blue} sfp:{red,green,blue})

LAST=${#LEDS[@]}
let "LAST2 = $LAST - 1"
echo $LAST2

for NUM in $(seq 1 ${LAST}); do
    let "PREVIOUS = $NUM - 1"
    if [[ $PREVIOUS -ne NONE ]]; then
        echo 0 > "/sys/class/leds/${LEDS[$PREVIOUS]}/brightness"
    fi
    if [[ $NUM -ne $LAST ]]; then
        echo 255 > "/sys/class/leds/${LEDS[$NUM]}/brightness"
    fi
    sleep 0.3
done
