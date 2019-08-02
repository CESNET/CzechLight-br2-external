#!/bin/sh

# TODO: replace this with a RAUC config
echo <<EOF > ${BINARIES_DIR}/uEnv.txt
bootpart=0:1
devtype=mmc
bootdir=
bootfile=zImage
bootpartition=mmcblk0p2
set_mmc1=if test $board_name = A33515BB; then setenv bootpartition mmcblk1p2; fi
set_bootargs=setenv bootargs console=ttyO0,115200n8 root=/dev/${bootpartition} rw rootfstype=ext4 rootwait
uenvcmd=run set_mmc1; run set_bootargs;run loadimage;run loadfdt;printenv bootargs;bootz ${loadaddr} - ${fdtaddr}
EOF
