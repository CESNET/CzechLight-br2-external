#!/bin/sh

install -m 0644 -D $BINARIES_DIR/boot.scr $TARGET_DIR/boot/boot.scr

# prepare the static script with RAUC logic
${HOST_DIR}/bin/mkimage -C none -A arm -T script \
        -d ${BR2_EXTERNAL_CZECHLIGHT_PATH}/board/czechlight/beaglebone/rauc.scr.txt ${BINARIES_DIR}/rauc.scr
