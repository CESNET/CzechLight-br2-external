#!/bin/bash

# Ignore failures from systemd-journald-upload.service
# ----------------------------------------------------
# After migration to ietf-alarms based health state reporting we should
# keep the current settings, i.e., ignore alarms coming from this particular
# systemd-journald-upload.service
#
sysrepocfg --datastore=startup --format=json --module=ietf-alarms --import="${MIGRATIONS_DIRECTORY}/0003_ietf-alarms_shelve-journal-upload.json"
