#!/bin/bash

# Load initial data
# -----------------
# These data are imported into the sysrepo's startup datastore only once. This happens either when the box is restored to
# its factory settings (the box is new and boots for the first time or someone deletes the startup.json backup in /cfg)
# or when the box is upgraded from the state before the migrations were introduced (versions released before July 2022).
#
# It's OK for user to remove these settings from sysrepo startup DS.
# However, the data will NEVER get restored by us (unless somebody deletes /cfg/startup.json, see above).

case "${CZECHLIGHT}" in
    sdn-roadm-line*)
        sysrepocfg --datastore=startup --format=json --module=czechlight-roadm-device --import="${CLA_YANG}/sdn-roadm-line.json"
        ;;
    sdn-roadm-add-drop*)
        ;& # fallthrough
    sdn-roadm-hires-add-drop*)
        sysrepocfg --datastore=startup --format=json --module=czechlight-roadm-device --import="${CLA_YANG}/sdn-roadm-add-drop.json"
        ;;
    sdn-roadm-coherent-a-d*)
        sysrepocfg --datastore=startup --format=json --module=czechlight-coherent-add-drop --import="${CLA_YANG}/sdn-roadm-coherent-a-d.json"
        ;;
    sdn-inline*)
        sysrepocfg --datastore=startup --format=json --module=czechlight-inline-amp --import="${CLA_YANG}/sdn-inline.json"
        ;;
    calibration-box)
        sysrepocfg --datastore=startup --format=json --module=czechlight-calibration-device --import="${CLA_YANG}/calibration-box.json"
        ;;
esac
