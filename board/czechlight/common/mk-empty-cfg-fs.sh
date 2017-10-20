#!/bin/sh

CFG_FS=${BINARIES_DIR}/cfg.ext4
rm -f ${CFG_FS}
${HOST_DIR}/sbin/mkfs.ext4 -L cfg ${CFG_FS} 256M
