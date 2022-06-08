#!/bin/bash

set -ex

YANG_ROADM=0
YANG_COHERENT=0
YANG_INLINE=0
YANG_CALIBRATION=0

CLA_YANG=/usr/share/cla-sysrepo/yang
VELIA_YANG=/usr/share/velia/yang
REPO=/etc/sysrepo/yang

for ARG in $(cat /proc/cmdline); do
    case "${ARG}" in
        czechlight=*)
            CZECHLIGHT="${ARG:11}"
            ;;
    esac
done

INITIAL_DATA=${CZECHLIGHT%%-g2}

case "${CZECHLIGHT}" in
    sdn-roadm-line*)
        YANG_ROADM=1
        WITH_FEATURE=hw-line-9
        ;;
    sdn-roadm-add-drop*)
        YANG_ROADM=1
        WITH_FEATURE=hw-add-drop-20
        ;;
    sdn-roadm-hires-add-drop*)
        YANG_ROADM=1
        WITH_FEATURE="hw-add-drop-20 pre-wss-ocm"
        INITIAL_DATA=sdn-roadm-add-drop
        ;;
    sdn-roadm-coherent-a-d*)
        YANG_COHERENT=1
        ;;
    sdn-inline*)
        YANG_INLINE=1
        ;;
    calibration-box)
        YANG_CALIBRATION=1
        ;;
esac

sysrepoctl --search-dirs ${CLA_YANG} --install ${CLA_YANG}/iana-hardware@2018-03-13.yang
sysrepoctl --search-dirs ${CLA_YANG} --install ${CLA_YANG}/ietf-hardware@2018-03-13.yang
sysrepoctl --change ietf-hardware --permissions 0660 --enable-feature hardware-sensor

if [[ ${YANG_ROADM} == 1 ]]; then
    FEATURE_ARGS=""
    if [[ ${WITH_FEATURE} ]]; then
        for FEATURE in ${WITH_FEATURE}; do
            FEATURE_ARGS="${FEATURE_ARGS} --enable-feature ${FEATURE}"
        done
    fi
    sysrepoctl --search-dirs ${CLA_YANG} --install ${CLA_YANG}/czechlight-roadm-device@2021-03-05.yang ${FEATURE_ARGS} --permissions 0660
    sysrepocfg --datastore=startup --format=json --module=czechlight-roadm-device --import="${CLA_YANG}/${INITIAL_DATA}.json"
fi

if [[ ${YANG_COHERENT} == 1 ]]; then
    sysrepoctl --search-dirs ${CLA_YANG} --install ${CLA_YANG}/czechlight-coherent-add-drop@2021-03-05.yang --permissions 0660
    sysrepocfg --datastore=startup --format=json --module=czechlight-coherent-add-drop --new-data="${CLA_YANG}/${INITIAL_DATA}.json"
    sysrepoctl --change czechlight-coherent-add-drop --permissions 0660
fi

if [[ ${YANG_INLINE} == 1 ]]; then
    sysrepoctl --search-dirs ${CLA_YANG} --install ${CLA_YANG}/czechlight-inline-amp@2021-03-05.yang --permissions 0660
    sysrepocfg --datastore=startup --format=json --module=czechlight-inline-amp --import="${CLA_YANG}/${INITIAL_DATA}.json"
fi

if [[ ${YANG_CALIBRATION} == 1 ]]; then
    sysrepoctl --search-dirs ${CLA_YANG} --install ${CLA_YANG}/czechlight-calibration-device@2019-06-25.yang --permissions 0660
    sysrepocfg --datastore=startup --format=json --module=czechlight-calibration-device --import="${CLA_YANG}/${INITIAL_DATA}.json"
fi

sysrepoctl --search-dirs ${VELIA_YANG} --install ${VELIA_YANG}/ietf-system@2014-08-06.yang --permissions 0660

sysrepoctl --search-dirs ${VELIA_YANG} --install ${VELIA_YANG}/czechlight-lldp@2020-11-04.yang --permissions 0660

sysrepoctl --search-dirs ${VELIA_YANG} --install ${VELIA_YANG}/czechlight-system@2021-01-13.yang --permissions 0660

sysrepoctl --search-dirs ${VELIA_YANG} --install ${VELIA_YANG}/iana-if-type@2017-01-19.yang
sysrepoctl --search-dirs ${VELIA_YANG} --install ${VELIA_YANG}/ietf-interfaces@2018-02-20.yang --permissions 0660
sysrepoctl --search-dirs ${VELIA_YANG} --install ${VELIA_YANG}/ietf-ip@2018-02-22.yang --permissions 0660
sysrepoctl --search-dirs ${VELIA_YANG} --install ${VELIA_YANG}/ietf-routing@2018-03-13.yang --permissions 0660
sysrepoctl --search-dirs ${VELIA_YANG} --install ${VELIA_YANG}/ietf-ipv4-unicast-routing@2018-03-13.yang --permissions 0660
sysrepoctl --search-dirs ${VELIA_YANG} --install ${VELIA_YANG}/ietf-ipv6-unicast-routing@2018-03-13.yang --permissions 0660
sysrepoctl --search-dirs ${VELIA_YANG} --install ${VELIA_YANG}/czechlight-network@2021-02-22.yang --permissions 0660

sysrepoctl --search-dirs ${VELIA_YANG} --install ${VELIA_YANG}/czechlight-firewall@2021-01-25.yang --permissions 0600
sysrepoctl --change ietf-access-control-list --enable-feature match-on-eth --enable-feature eth --enable-feature match-on-ipv4 --enable-feature ipv4 --enable-feature match-on-ipv6 --enable-feature ipv6 --enable-feature mixed-eth-ipv4-ipv6

# If not do not copy here from startup -> running, running might be stale.
sysrepocfg -C startup
