#!/bin/bash

set -eux

sed -i -E "s/(#?)ShutdownWatchdogSec=(.*)/ShutdownWatchdogSec=60/" ${TARGET_DIR}/etc/systemd/system.conf
sed -i -E "s/(#?)RuntimeWatchdogSec=(.*)/RuntimeWatchdogSec=60/" ${TARGET_DIR}/etc/systemd/system.conf
