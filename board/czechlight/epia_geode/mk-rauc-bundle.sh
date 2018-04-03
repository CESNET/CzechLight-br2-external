#!/bin/sh

RAUC_BUILD_DIR=${BUILD_DIR}/rauc-work-tmp
RAUC_IMAGE=${BINARIES_DIR}/update.raucb
ROOTFS_NAME=rootfs.tar.xz
EMPTY_TAR_NAME=cfg.tar.xz
RAUC_HOOK=${RAUC_BUILD_DIR}/hook.sh

rm -rf ${RAUC_BUILD_DIR}
mkdir ${RAUC_BUILD_DIR}
rm -f ${RAUC_IMAGE}

ln ${BINARIES_DIR}/${ROOTFS_NAME} ${RAUC_BUILD_DIR}/
tar -cJf ${RAUC_BUILD_DIR}/${EMPTY_TAR_NAME} -T /dev/null
cp ${BR2_EXTERNAL_CZECHLIGHT_PATH}/board/czechlight/common/rauc-hook.sh ${RAUC_HOOK}
cat > ${RAUC_BUILD_DIR}/manifest.raucm << EOF
[update]
compatible=czechlight-neophotonics-vmux
version=dev

[hooks]
filename=hook.sh

[image.rootfs]
filename=${ROOTFS_NAME}

[image.cfg]
filename=${EMPTY_TAR_NAME}
hooks=post-install
EOF

rauc \
  --cert ${BR2_EXTERNAL_CZECHLIGHT_PATH}/crypto/rauc-cert.pem \
  --key ${BR2_EXTERNAL_CZECHLIGHT_PATH}/crypto/rauc-key.pem \
  bundle ${RAUC_BUILD_DIR} ${RAUC_IMAGE}
