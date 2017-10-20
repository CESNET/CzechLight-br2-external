#!/bin/sh

RAUC_BUILD_DIR=${BUILD_DIR}/rauc-work-tmp
RAUC_IMAGE=${BINARIES_DIR}/update.raucb
ROOTFS_NAME=rootfs.tar.xz

rm -rf ${RAUC_BUILD_DIR}
mkdir ${RAUC_BUILD_DIR}
rm -f ${RAUC_IMAGE}

ln ${BINARIES_DIR}/${ROOTFS_NAME} ${RAUC_BUILD_DIR}/
cat > ${RAUC_BUILD_DIR}/manifest.raucm << EOF
[update]
compatible=czechlight-clearfog
version=dev

[image.rootfs]
filename=${ROOTFS_NAME}
EOF

rauc \
  --cert ${BR2_EXTERNAL_CZECHLIGHT_PATH}/crypto/rauc-cert.pem \
  --key ${BR2_EXTERNAL_CZECHLIGHT_PATH}/crypto/rauc-key.pem \
  bundle ${RAUC_BUILD_DIR} ${RAUC_IMAGE}
