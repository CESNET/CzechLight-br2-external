#!/bin/sh

sed -i 's|^\(/dev/root.*\) ro|\1 rw|' ${TARGET_DIR}/etc/fstab
