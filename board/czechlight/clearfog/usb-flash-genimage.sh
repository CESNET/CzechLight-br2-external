#!/bin/sh

set -ex

mksquashfs ${BINARIES_DIR}/sdcard.img ${BINARIES_DIR}/sdcard.img.squashfs -root-owned -comp gzip -progress

GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
rm -rf "${GENIMAGE_TMP}"

genimage --rootpath "${TARGET_DIR}" --tmppath "${GENIMAGE_TMP}" --inputpath "${BINARIES_DIR}" --outputpath "${BINARIES_DIR}" --config "${BR2_EXTERNAL_CZECHLIGHT_PATH}/board/czechlight/clearfog/usb-genimage.cfg"
