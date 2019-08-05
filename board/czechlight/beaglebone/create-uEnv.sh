#!/bin/sh

install -m 0644 -D $BINARIES_DIR/boot.scr $TARGET_DIR/boot/boot.scr

# TODO: replace this with a RAUC config
cp ${BR2_EXTERNAL_CZECHLIGHT_PATH}/board/czechlight/beaglebone/uEnv.txt ${BINARIES_DIR}/uEnv.txt
