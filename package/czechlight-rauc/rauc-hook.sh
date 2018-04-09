#!/bin/sh

case "$1" in
  slot-post-install)
    case "$RAUC_SLOT_CLASS" in
      cfg)
        if [[ -d /cfg/etc ]]; then
          cp -a /cfg/etc ${RAUC_SLOT_MOUNT_POINT}/
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

exit 0
