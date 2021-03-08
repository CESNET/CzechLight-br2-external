#!/bin/bash

set -ex

YANG_ROADM=0
YANG_COHERENT=0
YANG_INLINE=0
YANG_CALIBRATION=0

YANG_DIR=/usr/share/cla-sysrepo/yang
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
        WITH_FEATURE=hw-add-drop-20
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

sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/iana-hardware@2018-03-13.yang
sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/ietf-hardware@2018-03-13.yang
sysrepoctl --change ietf-hardware --permissions 0664 --enable-feature hardware-sensor --apply

if [[ ${YANG_ROADM} == 1 ]]; then
    sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/czechlight-roadm-device@2021-03-05.yang
    sysrepoctl --change czechlight-roadm-device --group optics --permissions 0664 --apply
    if [[ ${WITH_FEATURE} ]]; then
        sysrepoctl --change czechlight-roadm-device --enable-feature ${WITH_FEATURE}
    fi
    sysrepocfg --datastore=startup --format=json --module=czechlight-roadm-device --import="${YANG_DIR}/${INITIAL_DATA}.json"
fi

if [[ ${YANG_COHERENT} == 1 ]]; then
    sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/czechlight-coherent-add-drop@2021-03-05.yang
    sysrepocfg --datastore=startup --format=json --module=czechlight-coherent-add-drop --new-data="${YANG_DIR}/${INITIAL_DATA}.json"
    sysrepoctl --change czechlight-coherent-add-drop --group optics --permissions 0664 --apply
fi

if [[ ${YANG_INLINE} == 1 ]]; then
    sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/czechlight-inline-amp@2021-03-05.yang
    sysrepocfg --datastore=startup --format=json --module=czechlight-inline-amp --import="${YANG_DIR}/${INITIAL_DATA}.json"
    sysrepoctl --change czechlight-inline-amp --group optics --permissions 0664 --apply
fi

if [[ ${YANG_CALIBRATION} == 1 ]]; then
    sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/czechlight-calibration-device@2019-06-25.yang
    sysrepocfg --datastore=startup --format=json --module=czechlight-calibration-device --import="${YANG_DIR}/${INITIAL_DATA}.json"
    sysrepoctl --change czechlight-calibration-device --group optics --permissions 0664 --apply
fi

sysrepoctl --search-dirs /usr/share/velia/yang --install /usr/share/velia/yang/ietf-system@2014-08-06.yang
sysrepoctl --change ietf-system --permissions 0664 --apply

sysrepoctl --search-dirs /usr/share/lldp-systemd-networkd-sysrepo/yang --install /usr/share/lldp-systemd-networkd-sysrepo/yang/czechlight-lldp@2020-11-04.yang
sysrepoctl --change czechlight-lldp --permissions 0664 --apply

sysrepoctl --search-dirs /usr/share/velia/yang --install /usr/share/velia/yang/czechlight-system@2021-01-13.yang
sysrepoctl --change czechlight-system --permissions 0664 --apply

sysrepoctl --search-dirs /usr/share/velia/yang --install /usr/share/velia/yang/iana-if-type@2017-01-19.yang
sysrepoctl --search-dirs /usr/share/velia/yang --install /usr/share/velia/yang/ietf-interfaces@2018-02-20.yang
sysrepoctl --change ietf-interfaces --permissions 0664 --apply

sysrepoctl --search-dirs /usr/share/velia/yang --install /usr/share/velia/yang/ietf-ip@2018-02-22.yang
sysrepoctl --change ietf-ip --permissions 0664 --apply

sysrepoctl --search-dirs /usr/share/velia/yang --install /usr/share/velia/yang/ietf-routing@2018-03-13.yang
sysrepoctl --change ietf-routing --permissions 0664 --apply

sysrepoctl --search-dirs /usr/share/velia/yang --install /usr/share/velia/yang/ietf-ipv4-unicast-routing@2018-03-13.yang
sysrepoctl --change ietf-ipv4-unicast-routing --permissions 0664 --apply
sysrepoctl --search-dirs /usr/share/velia/yang --install /usr/share/velia/yang/ietf-ipv6-unicast-routing@2018-03-13.yang
sysrepoctl --change ietf-ipv6-unicast-routing --permissions 0664 --apply

sysrepoctl --search-dirs /usr/share/velia/yang --install /usr/share/velia/yang/czechlight-network@2021-02-22.yang
sysrepoctl --change czechlight-network --permissions 0664 --apply

sysrepoctl --search-dirs /usr/share/velia/yang --install /usr/share/velia/yang/czechlight-firewall@2021-01-25.yang
sysrepoctl --change czechlight-firewall --permissions 0600 --apply
sysrepoctl --change ietf-access-control-list --enable-feature eth --enable-feature match-on-eth --enable-feature match-on-ipv4 --enable-feature ipv4 --enable-feature match-on-ipv6 --enable-feature ipv6 --enable-feature mixed-eth-ipv4-ipv6

# If not do not copy here from startup -> running, running might be stale.
sysrepocfg -C startup
