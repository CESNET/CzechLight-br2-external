#!/bin/bash

# setup default configuration for ietf-interfaces in startup DS
# This overwrites current networking setup

set -x
set -e

case "${CZECHLIGHT}" in
    sdn-roadm-add-drop*)
        ;&
    sdn-roadm-hires-add-drop*)
        ;&
    sdn-roadm-coherent-a-d*)
        sysrepocfg --datastore=startup --format=json --module=ietf-interfaces --import="${MIGRATIONS_DIRECTORY}/0002_ietf-interfaces_default-startup-config_add-drop.json"
        ;;
    sdn-inline*)
        sysrepocfg --datastore=startup --format=json --module=ietf-interfaces --import="${MIGRATIONS_DIRECTORY}/0002_ietf-interfaces_default-startup-config_sdn-inline.json"
        ;;
    sdn-roadm-line*)
        sysrepocfg --datastore=startup --format=json --module=ietf-interfaces --import="${MIGRATIONS_DIRECTORY}/0002_ietf-interfaces_default-startup-config.json"
        ;;
esac
