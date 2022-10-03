#!/bin/bash

# Ignore failures from systemd-journal-upload.service
# ---------------------------------------------------
# After migration to ietf-alarms based health state reporting we should
# keep the current settings, i.e., ignore alarms coming from this particular
# systemd-journal-upload.service
#
sysrepocfg --datastore=startup --format=json --module=ietf-alarms --import="${MIGRATIONS_DIRECTORY}/0003_ietf-alarms_shelve-journal-upload.json"
