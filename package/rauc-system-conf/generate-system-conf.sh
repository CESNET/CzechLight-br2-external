#!/bin/sh

cat - << EOF
[system]
compatible=
bootloader=BOOTLOADER_NAME

[keyring]
path=/etc/rauc/keyring.pem

[slot.rootfs.0]
device=CZECHLIGHT_RAUC_SLOT_A_ROOTFS_DEV
type=ext4
bootname=A

[slot.cfg.0]
device=CZECHLIGHT_RAUC_SLOT_A_CFG_DEV
type=ext4
parent=rootfs.0
ignore-checksum=true

[slot.rootfs.1]
device=CZECHLIGHT_RAUC_SLOT_B_ROOTFS_DEV
type=ext4
bootname=B

[slot.cfg.1]
device=CZECHLIGHT_RAUC_SLOT_B_CFG_DEV
type=ext4
parent=rootfs.1
ignore-checksum=true
EOF
