#!/bin/sh

set -ex

mkdir /tmp/sdcard.image
mount /mnt/sdcard.img.squashfs /tmp/sdcard.image/
ddrescue --force /tmp/sdcard.image/sdcard.img /dev/mmcblk0
echo 0 > /sys/block/mmcblk0boot0/force_ro
ddrescue --force /mnt/u-boot-spl.kwb /dev/mmcblk0boot0
echo 1 > /sys/block/mmcblk0boot0/force_ro
echo 0 > /sys/block/mmcblk0boot1/force_ro
ddrescue --force /mnt/u-boot-spl.kwb /dev/mmcblk0boot1
echo 1 > /sys/block/mmcblk0boot1/force_ro
sync
echo b > /proc/sysrq-trigger
