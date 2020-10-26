#!/bin/sh

${BR2_EXTERNAL_CZECHLIGHT_PATH}/board/czechlight/copy-boot-scr.sh

${BR2_EXTERNAL_CZECHLIGHT_PATH}/board/czechlight/common/os-release.sh

# enable about 250MB of ramfs for the journal log
sed -i -n \
	-e '/\s\/run\s/!p' \
	-e '$a tmpfs /run tmpfs rw,nosuid,nodev,size=256000k,nr_inodes=819200,mode=755' \
	${TARGET_DIR}/etc/fstab
