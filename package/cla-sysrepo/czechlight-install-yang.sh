#!/bin/bash

set -ex

IETF_HW_STATE=0
YANG_ROADM=0
YANG_COHERENT=0
YANG_INLINE=0
YANG_CALIBRATION=0

YANG_DIR=/usr/share/cla-sysrepo/yang
REPO=/etc/sysrepo/yang

for ARG in $(cat /proc/cmdline); do
    case "${ARG}" in
        czechlight=*)
            CZECHLIGHT="${CZECHLIGHT:11}"
            ;;
    esac
done

case "${CZECHLIGHT}" in
    sdn-roadm-line)
        YANG_ROADM=1
        WITH_FEATURE=hw-line-9
        IETF_HW_STATE=1
        ;;
    sdn-roadm-add-drop)
        YANG_ROADM=1
        WITH_FEATURE=hw-add-drop-20
        IETF_HW_STATE=1
        ;;
    sdn-roadm-coherent-a-d)
        IETF_HW_STATE=1
        YANG_COHERENT=1
        ;;
    sdn-inline)
        IETF_HW_STATE=1
        YANG_INLINE=1
        ;;
    calibration-box)
        YANG_CALIBRATION=1
        ;;
esac

if [[ ${IETF_HW_STATE} == 1 && ! -f ${REPO}/ietf-hardware-state@2018-03-13.yang ]]; then
    sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/iana-hardware@2018-03-13.yang
    sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/ietf-hardware-state@2018-03-13.yang
fi

if [[ ${YANG_ROADM} == 1 && ! -f ${REPO}/czechlight-roadm-device@2019-09-30.yang ]]; then
    sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/czechlight-roadm-device.yang
    if [ -z ${WITH_FEATURE+x} ]; then
        sysrepoctl --change czechlight-roadm-device --enable-feature ${WITH_FEATURE}
    fi
    sysrepocfg --datastore=startup --format=json --module=czechlight-roadm-device --import="${YANG_DIR}/${CZECHLIGHT}.json"
fi

if [[ ${YANG_COHERENT} == 1 && ! -f ${REPO}/czechlight-coherent-add-drop@2019-09-30.yang ]]; then
    sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/czechlight-coherent-add-drop.yang
    sysrepocfg --datastore=startup --format=json --module=czechlight-coherent-add-drop --new-data="${YANG_DIR}/${CZECHLIGHT}.json"
fi

if [[ ${YANG_INLINE} == 1 && ! -f ${REPO}/czechlight-inline-amp@2019-09-30.yang ]]; then
    sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/czechlight-inline-amp.yang
    sysrepocfg --datastore=startup --format=json --module=czechlight-inline-amp --import="${YANG_DIR}/${CZECHLIGHT}.json"
fi

if [[ ${YANG_INLINE} == 1 && ! -f ${REPO}/czechlight-calibration-device@2019-06-25.yang ]]; then
    sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/czechlight-calibration-device.yang
    sysrepocfg --datastore=startup --format=json --module=czechlight-calibration-device --import="${YANG_DIR}/${CZECHLIGHT}.json"
fi

sysrepoctl --search-dirs /usr/share/lldp-systemd-networkd-sysrepo/yang --install /usr/share/lldp-systemd-networkd-sysrepo/yang/czechlight-lldp.yang --apply
