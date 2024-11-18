#!/usr/bin/env sh
grep -v \
    -e 'usr/bin/cla-.*$' \
    -e 'usr/bin/netconf-cli$' \
    -e 'usr/bin/sysrepo-cli$' \
    -e 'usr/bin/rousette$' \
    -e 'usr/bin/veliad-.*$' \
    -e 'usr/bin/sysrepo-ietf-alarmsd$'
