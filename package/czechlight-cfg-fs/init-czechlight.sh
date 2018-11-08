#!/bin/sh

echo "Preparing /etc overlay"
/bin/mount -t tmpfs tmpfs /.ov -o mode=0700
/bin/mkdir /.ov/etc-u
/bin/mkdir /.ov/etc-w
/bin/mount overlay -t overlay /etc -olowerdir=/etc,upperdir=/.ov/etc-u,workdir=/.ov/etc-w

/bin/mount -t proc proc /proc -o rw,nosuid,nodev,noexec,relatime
if grep -q rauc.slot=A /proc/cmdline; then
  RAUC_SLOT_NO=0
  RAUC_SLOT_NAME=A
elif grep -q rauc.slot=B /proc/cmdline; then
  RAUC_SLOT_NO=1
  RAUC_SLOT_NAME=B
else
  echo "Cannot determine active RAUC rootfs slot"
  #exit 1
fi
/bin/umount /proc
echo "RAUC: active slot ${RAUC_SLOT_NAME}"

# sed magic:
# 1) use `sed -n` so that we only print what's explicitly printed
# 2) anchor the search between the "[slot.cfg.$RAUC_SLOT_NO]" and any other section
# 3) look for a line beginning with "device="
# 4) take stuff which is behind the "="
# 5) print it
DEVICE=$(sed -n "/\[slot\.cfg\.${RAUC_SLOT_NO}\]/,/\[.*\]/{/^device=/s/\(.*\)=\(.*\)/\\2/p}" /etc/rauc/system.conf)

if [ x$DEVICE = x ]; then
  echo "Cannot determine device for /cfg from RAUC"
  #exit 1
fi

if [ ! -b $DEVICE ]; then
  echo "Device ${DEVICE} is not a block device"
  #exit 1
fi

echo "Mounting /cfg"
/bin/mount ${DEVICE} /cfg -t auto -o relatime,nosuid,nodev

if [ -d /cfg/etc ]; then
  echo "Restoring /etc from /cfg"
  /bin/cp -a /cfg/etc/* /etc/
fi

exec /sbin/init
