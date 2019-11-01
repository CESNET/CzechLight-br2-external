#!/bin/sh

case "$1" in
  slot-post-install)
    case "$RAUC_SLOT_CLASS" in
      cfg)
        # whitelist so that we don't copy cruft or lost+found
        for ITEM in \
            etc \
            random-seed \
            ssh-user-auth \
            ; do
          if [[ -d /cfg/${ITEM} ]]; then
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

exit 0
