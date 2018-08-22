#!/bin/sh

set -ex

mkdir /tmp/sdcard.image
mount /mnt/sdcard.img.squashfs /tmp/sdcard.image/
blkdiscard /dev/mmcblk0
ddrescue --force /tmp/sdcard.image/sdcard.img /dev/mmcblk0

echo 0 > /sys/block/mmcblk0boot0/force_ro
echo 0 > /sys/block/mmcblk0boot1/force_ro

ddrescue --force /mnt/u-boot-spl.kwb /dev/mmcblk0boot0
ddrescue --force /mnt/u-boot-spl.kwb /dev/mmcblk0boot1

fsck -y /dev/mmcblk0p1 || true
fsck -y /dev/mmcblk0p2 || true
fsck -y /dev/mmcblk0p3 || true
fsck -y /dev/mmcblk0p4 || true

sync
echo 1 > /sys/block/mmcblk0boot1/force_ro
echo 1 > /sys/block/mmcblk0boot0/force_ro

echo b > /proc/sysrq-trigger
