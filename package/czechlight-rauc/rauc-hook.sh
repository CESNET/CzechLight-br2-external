#!/bin/sh

case "$1" in
  slot-post-install)
    case "$RAUC_SLOT_CLASS" in
      cfg)
        # whitelist so that we don't copy cruft or lost+found
        for ITEM in \
            calibration \
            etc \
            journald-remote \
            random-seed \
            sysrepo-startup \
            ssh-user-auth \
            ; do
          if [[ -d /cfg/${ITEM} || -f /cfg/${ITEM} ]]; then
            cp -a /cfg/${ITEM} ${RAUC_SLOT_MOUNT_POINT}/
          fi
        done
        ;;
      *)
        echo "Internal error: hook mismatched"
        exit 11
    esac
    ;;
  *)
    echo "Internal error: unrecognized hook"
    exit 11
    ;;
esac

if [[ -f /lib/libsysrepo.so.0.7 ]]; then
  # Updating from old sysrepo with incompatible repository layout
  rm -rf ${RAUC_SLOT_MOUNT_POINT}/etc/sysrepo
  # No more netopeer2-keystored, different config
  rm -rf ${RAUC_SLOT_MOUNT_POINT}/etc/keystored
  echo "sysrepo configuration not preserved"
elif [[ -f /cfg/etc/sysrepo ]]; then
  # persist only sysrepo startup data files
  rm -rf ${RAUC_SLOT_MOUNT_POINT}/etc/sysrepo
  mkdir ${RAUC_SLOT_MOUNT_POINT}/sysrepo-startup
  cp -a /cfg/etc/sysrepo/data/*.startup ${RAUC_SLOT_MOUNT_POINT}/sysrepo-startup
fi

exit 0
