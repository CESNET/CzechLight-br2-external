#!/bin/sh

CURRENT_CONFIG_FILE=/usr/libexec/czechlight-cfg-fs/CURRENT_CONFIG_VERSION

case "$1" in
  slot-post-install)
    case "$RAUC_SLOT_CLASS" in
      cfg)
        # whitelist so that we don't copy cruft or lost+found
        for ITEM in \
            calibration \
            etc \
            journald-remote \
            network \
            random-seed \
            sysrepo \
            ssh-user-auth \
            ; do
          if [[ -d /cfg/${ITEM} || -f /cfg/${ITEM} ]]; then
            cp -a /cfg/${ITEM} ${RAUC_SLOT_MOUNT_POINT}/
          fi
        done

        # migrate network files from <interface>.network pattern to 10-<interface>.network
        if [[ ! -f "$CURRENT_CONFIG_FILE" || $(cat $CURRENT_CONFIG_FILE) -le 10 ]]; then
            for file in ${RAUC_SLOT_MOUNT_POINT}/network/*.network; do
                if [[ ! $(basename "$file") =~ ^[0-9][0-9]-.+\.network$ ]]; then
                    mv "$file" "${RAUC_SLOT_MOUNT_POINT}/network/10-$(basename "$file")"
                fi
            done
        fi
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
  echo "sysrepo configuration not preserved (incompatible layout, too old version, standalone keystored)"
elif [[ -d /cfg/etc/sysrepo ]]; then
  # switch from "persisting whole /etc/sysrepo" to "exporting config via JSON"
  rm -rf ${RAUC_SLOT_MOUNT_POINT}/etc/sysrepo
  echo "sysrepo configuration not preserved (copy of the whole /etc/sysrepo)"
fi

exit 0
