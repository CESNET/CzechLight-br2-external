#!/bin/bash

for LED in /sys/class/leds/*/brightness; do
    echo 0 > $LED
done
sleep 1

LEDS=(NONE led5:{red,green,blue} line-c:{red,green,blue} line-west:{red,green,blue} status:{red,green,blue} uid:{red,green,blue} line:{red,green,blue} express:{red,green,blue} line-east:{red,green,blue} line-l:{red,green,blue} sfp:{red,green,blue} port1:{red,green} port2:{red,green} port3:{red,green} port4:{red,green} port5:{red,green} port6:{red,green} port7:{red,green} port8:{red,green})

LAST=${#LEDS[@]}
let "LAST2 = $LAST - 1"
echo $LAST2

for NUM in $(seq 1 ${LAST}); do
    let "PREVIOUS = $NUM - 1"
    if [[ $PREVIOUS -ne NONE ]]; then
        echo 0 > "/sys/class/leds/${LEDS[$PREVIOUS]}/brightness"
    fi
    if [[ $NUM -ne $LAST ]]; then
        echo 256 > "/sys/class/leds/${LEDS[$NUM]}/brightness"
    fi
    if [[ ! -d "/sys/class/leds/${LEDS[$NUM]}" ]]; then
        echo "No LED ${LEDS[$NUM]}"
    else
        sleep 0.3
    fi
done
