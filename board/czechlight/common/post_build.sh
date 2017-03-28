#!/bin/sh

set -ex

cd ${TARGET_DIR}
rm -rf etc/network
rm -f etc/resolv.conf
rmdir media mnt opt var/www || true
rm -f var/lib/misc
rm -rf var/{cache,lock,log,run,spool,tmp}
