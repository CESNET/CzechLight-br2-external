#!/bin/sh

case "$1" in
  slot-post-install)
    case "$RAUC_SLOT_CLASS" in
      cfg)
        for DIR in etc ssh-user-auth; do
          if [[ -d /cfg/$DIR ]]; then
            cp -a /cfg/$DIR ${RAUC_SLOT_MOUNT_POINT}/
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
