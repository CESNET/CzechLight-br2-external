#!/bin/sh

set -ex

# reset the LEDs
i2cset -y 1 0x6b 0xa5 0x5a || true
# configure for fast blinking
i2cset -y 1 0x60 0x00 0x01 || true
i2cset -y 1 0x60 0x01 0x20 || true
i2cset -y 1 0x60 0x12 0x40 || true
i2cset -y 1 0x60 0x13 0x04 || true
i2cset -y 1 0x60 0x0a 0xff || true
i2cset -y 1 0x60 0x0b 0xff || true
i2cset -y 1 0x60 0x0c 0xff || true
# yellow blinking
i2cset -y 1 0x60 0x16 0x0f || true

busctl set-property org.freedesktop.systemd1 /org/freedesktop/systemd1 org.freedesktop.systemd1.Manager RuntimeWatchdogUSec t 30000000

mkdir /tmp/sdcard.image
mount /mnt/sdcard.img.squashfs /tmp/sdcard.image/
blkdiscard -f /dev/mmcblk0
ddrescue --force /tmp/sdcard.image/sdcard.img /dev/mmcblk0

echo 0 > /sys/block/mmcblk0boot0/force_ro
echo 0 > /sys/block/mmcblk0boot1/force_ro

ddrescue --force /mnt/u-boot-spl.kwb /dev/mmcblk0boot0
ddrescue --force /mnt/u-boot-spl.kwb /dev/mmcblk0boot1

# solid yellow
i2cset -y 1 0x60 0x16 0x05 || true

fsck -y /dev/mmcblk0p1 || true
fsck -y /dev/mmcblk0p2 || true
fsck -y /dev/mmcblk0p3 || true
fsck -y /dev/mmcblk0p4 || true

sync
echo 1 > /sys/block/mmcblk0boot1/force_ro
echo 1 > /sys/block/mmcblk0boot0/force_ro

# solid white
i2cset -y 1 0x60 0x16 0x15 || true

echo b > /proc/sysrq-trigger
