#!/bin/sh

install -m 0644 -D $BINARIES_DIR/boot.scr $TARGET_DIR/boot/boot.scr
install -m 0644 -D $BINARIES_DIR/u-boot-with-spl.kwb $TARGET_DIR/usr/libexec/u-boot-with-spl.kwb

# Prepare a boot script for USB booting as well
${HOST_DIR}/bin/mkimage -C none -A arm -T script \
	-d ${BR2_EXTERNAL_CZECHLIGHT_PATH}/board/czechlight/clearfog/usb-boot.scr.txt ${BINARIES_DIR}/usb-boot.scr
