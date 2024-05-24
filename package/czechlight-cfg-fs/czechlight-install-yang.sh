#!/bin/bash

set -ex

CLA_YANG="${CLA_YANG:-/usr/share/cla-sysrepo/yang}"
VELIA_YANG="${VELIA_YANG:-/usr/share/velia/yang}"
ALARMS_YANG="${ALARMS_YANG:-/usr/share/sysrepo-ietf-alarms/yang}"
ROUSETTE_YANG="${ROUSETTE_YANG:-/usr/share/rousette/yang}"
PROC_CMDLINE="${PROC_CMDLINE:-/proc/cmdline}"

for ARG in $(cat "$PROC_CMDLINE"); do
    case "${ARG}" in
        czechlight=*)
            CZECHLIGHT="${ARG:11}"
            ;;
    esac
done

case "${CZECHLIGHT}" in
    sdn-roadm-line*)
        DEVICE_YANG="--install ${CLA_YANG}/czechlight-roadm-device@2021-03-05.yang --enable-feature hw-line-9"
        ;;
    sdn-roadm-add-drop*)
        DEVICE_YANG="--install ${CLA_YANG}/czechlight-roadm-device@2021-03-05.yang --enable-feature hw-add-drop-20"
        ;;
    sdn-roadm-hires-add-drop*)
        DEVICE_YANG="--install ${CLA_YANG}/czechlight-roadm-device@2021-03-05.yang --enable-feature hw-add-drop-20 --enable-feature pre-wss-ocm"
        ;;
    sdn-roadm-coherent-a-d*)
        DEVICE_YANG="--install ${CLA_YANG}/czechlight-coherent-add-drop@2021-03-05.yang"
        ;;
    sdn-inline*)
        DEVICE_YANG="--install ${CLA_YANG}/czechlight-inline-amp@2021-03-05.yang"
        ;;
    calibration-box)
        DEVICE_YANG="--install ${CLA_YANG}/czechlight-calibration-device@2019-06-25.yang"
        ;;
    sdn-bidi-cplus1572-g2)
        DEVICE_YANG="--install ${CLA_YANG}/czechlight-bidi-amp@2022-03-22.yang --enable-feature dualband-c-plus-1572"
        ;;
    sdn-bidi-cplus1572-ocm-g2)
        DEVICE_YANG="--install ${CLA_YANG}/czechlight-bidi-amp@2022-03-22.yang --enable-feature dualband-c-plus-1572 --enable-feature c-band-ocm"
        ;;
esac

sysrepoctl \
    --search-dirs ${CLA_YANG}:${VELIA_YANG}:${ALARMS_YANG}:${ROUSETTE_YANG} \
    --install ${CLA_YANG}/iana-hardware@2018-03-13.yang \
    --install ${CLA_YANG}/ietf-hardware@2018-03-13.yang \
        --enable-feature hardware-sensor \
        --enable-feature hardware-state \
    --install ${ALARMS_YANG}/ietf-alarms@2019-09-11.yang \
        --enable-feature alarm-shelving \
        --enable-feature alarm-summary \
    --install ${ALARMS_YANG}/sysrepo-ietf-alarms@2022-02-17.yang \
    --install ${VELIA_YANG}/ietf-system@2014-08-06.yang \
    --install ${VELIA_YANG}/czechlight-lldp@2020-11-04.yang \
    --install ${VELIA_YANG}/czechlight-system@2022-07-08.yang \
    --install ${VELIA_YANG}/iana-if-type@2017-01-19.yang \
    --install ${VELIA_YANG}/ietf-interfaces@2018-02-20.yang \
    --install ${VELIA_YANG}/ietf-ip@2018-02-22.yang \
    --install ${VELIA_YANG}/ietf-routing@2018-03-13.yang \
    --install ${VELIA_YANG}/ietf-ipv4-unicast-routing@2018-03-13.yang \
    --install ${VELIA_YANG}/ietf-ipv6-unicast-routing@2018-03-13.yang \
    --install ${VELIA_YANG}/czechlight-network@2021-02-22.yang \
    --install ${VELIA_YANG}/ietf-access-control-list@2019-03-04.yang \
        --enable-feature match-on-eth \
        --enable-feature eth \
        --enable-feature match-on-ipv4 \
        --enable-feature ipv4 \
        --enable-feature match-on-ipv6 \
        --enable-feature ipv6 \
        --enable-feature mixed-eth-ipv4-ipv6 \
    --install ${VELIA_YANG}/czechlight-firewall@2021-01-25.yang \
    --install ${VELIA_YANG}/velia-alarms@2022-07-12.yang \
    --install ${ROUSETTE_YANG}/ietf-restconf@2017-01-26.yang \
    ${DEVICE_YANG}
