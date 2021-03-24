#!/bin/sh
set -x

if echo fsp3y_yh5151e 0x25 > /sys/bus/i2c/devices/i2c-2/new_device; then
    systemctl restart velia-hardware-g1.service
    systemctl restart velia-hardware-g2.service
fi

register()
{
    echo fsp3y_ym2151e "0x$1" | tee /sys/bus/i2c/devices/i2c-2/new_device
}

unregister()
{
    echo "0x$1" | tee /sys/bus/i2c/devices/i2c-2/delete_device
}

impl()
{
    local RET=1
    if i2cget -f -y 2 "0x$1" && [ ! -d "/sys/bus/i2c/devices/2-00$1" ]; then
        register "$1"
        RET=0
    elif ! i2cget -f -y 2 "0x$1" && [ -d "/sys/bus/i2c/devices/2-00$1" ]; then
        unregister "$1"
        RET=0
    fi

    return $RET
}

while true; do
    impl 58
    RET_58=$?
    impl 59
    RET_59=$?

    if [ $RET_58 -eq 0 ] || [ $RET_59 -eq 0 ]; then
        systemctl restart velia-hardware-g1.service
        systemctl restart velia-hardware-g2.service
    fi

    sleep 3
done
