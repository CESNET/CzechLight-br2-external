#!/bin/sh

# TODO: replace this with a RAUC config
cat <<EOF > ${BINARIES_DIR}/uEnv.txt
uenvcmd=echo CzechLight BBB uEnv.txt;setenv bootargs console=ttyO0,115200n8 root=/dev/mmcblk0p2 ro;load mmc 0:2 \${loadaddr} boot/zImage;load mmc 0:2 \${fdtaddr} boot/czechlight-bbb.dtb;bootz \${loadaddr} - \${fdtaddr}
EOF
