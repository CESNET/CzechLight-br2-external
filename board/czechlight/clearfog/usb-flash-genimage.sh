#!/bin/sh

set -ex

install -m 0644 -D ${BR2_EXTERNAL_CZECHLIGHT_PATH}/board/czechlight/clearfog/usb-reflash-factory.sh ${BINARIES_DIR}/usb-reflash-factory.sh

mksquashfs ${BINARIES_DIR}/sdcard.img ${BINARIES_DIR}/sdcard.img.squashfs -root-owned -comp gzip -progress -noappend

GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"
rm -rf "${GENIMAGE_TMP}"

genimage --rootpath "${TARGET_DIR}" --tmppath "${GENIMAGE_TMP}" --inputpath "${BINARIES_DIR}" --outputpath "${BINARIES_DIR}" --config "${BR2_EXTERNAL_CZECHLIGHT_PATH}/board/czechlight/clearfog/usb-genimage.cfg"
