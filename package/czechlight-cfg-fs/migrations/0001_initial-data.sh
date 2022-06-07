#!/bin/bash

# load initial data

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
