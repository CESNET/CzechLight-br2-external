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
            CZECHLIGHT="${ARG:11}"
            ;;
    esac
done

INITIAL_DATA=${CZECHLIGHT%%-g2}

case "${CZECHLIGHT}" in
    sdn-roadm-line*)
        YANG_ROADM=1
        WITH_FEATURE=hw-line-9
        IETF_HW_STATE=1
        ;;
    sdn-roadm-add-drop*)
        YANG_ROADM=1
        WITH_FEATURE=hw-add-drop-20
        IETF_HW_STATE=1
        ;;
    sdn-roadm-hires-add-drop*)
        YANG_ROADM=1
        WITH_FEATURE=hw-add-drop-20
        IETF_HW_STATE=1
        INITIAL_DATA=sdn-roadm-add-drop
        ;;
    sdn-roadm-coherent-a-d*)
        IETF_HW_STATE=1
        YANG_COHERENT=1
        ;;
    sdn-inline*)
        IETF_HW_STATE=1
        YANG_INLINE=1
        ;;
    calibration-box)
        YANG_CALIBRATION=1
        ;;
esac

# asks ietf-yang-library model in sysrepo for the state of a module given by $1
# can return "implement", "import" or "" if the module is not present in the tree
yang-module-state() {
    sysrepocfg -f xml -X --xpath "/ietf-yang-library:modules-state/module[name='$1']/conformance-type" -d operational  | sed -n 's/\s*<conformance-type>\(.*\)<\/conformance-type>/\1/p'
}

if [[ ${IETF_HW_STATE} == 1 ]]; then
    # if old model is implemented, remove it first. This uninstall dependent ietf-hardware if imported and not implemented
    if [[ "$(yang-module-state ietf-hardware-state)" == "implement" ]]; then
        sysrepoctl -u ietf-hardware-state --apply
    fi

    # if new model is not implemented
    if [[ "$(yang-module-state ietf-hardware)" != "implement" ]]; then
        sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/iana-hardware@2018-03-13.yang
        sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/ietf-hardware@2018-03-13.yang
        sysrepoctl --change ietf-hardware --permissions 0664 --enable-feature hardware-sensor --apply
    fi
fi

if [[ ${YANG_ROADM} == 1 && ! -f ${REPO}/czechlight-roadm-device@2019-09-30.yang ]]; then
    sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/czechlight-roadm-device@2019-09-30.yang
    sysrepoctl --change czechlight-roadm-device --group optics --permissions 0664 --apply
    if [[ ${WITH_FEATURE} ]]; then
        sysrepoctl --change czechlight-roadm-device --enable-feature ${WITH_FEATURE}
    fi
    sysrepocfg --datastore=startup --format=json --module=czechlight-roadm-device --import="${YANG_DIR}/${INITIAL_DATA}.json"
fi

if [[ ${YANG_COHERENT} == 1 && ! -f ${REPO}/czechlight-coherent-add-drop@2019-09-30.yang ]]; then
    sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/czechlight-coherent-add-drop@2019-09-30.yang
    sysrepocfg --datastore=startup --format=json --module=czechlight-coherent-add-drop --new-data="${YANG_DIR}/${INITIAL_DATA}.json"
    sysrepoctl --change czechlight-coherent-add-drop --group optics --permissions 0664 --apply
fi

if [[ ${YANG_INLINE} == 1 && ! -f ${REPO}/czechlight-inline-amp@2019-09-30.yang ]]; then
    sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/czechlight-inline-amp@2019-09-30.yang
    sysrepocfg --datastore=startup --format=json --module=czechlight-inline-amp --import="${YANG_DIR}/${INITIAL_DATA}.json"
    sysrepoctl --change czechlight-inline-amp --group optics --permissions 0664 --apply
fi

if [[ ${YANG_CALIBRATION} == 1 && ! -f ${REPO}/czechlight-calibration-device@2019-06-25.yang ]]; then
    sysrepoctl --search-dirs ${YANG_DIR} --install ${YANG_DIR}/czechlight-calibration-device@2019-06-25.yang
    sysrepocfg --datastore=startup --format=json --module=czechlight-calibration-device --import="${YANG_DIR}/${INITIAL_DATA}.json"
    sysrepoctl --change czechlight-calibration-device --group optics --permissions 0664 --apply
fi

if [[ ! -f ${REPO}/ietf-system@2014-08-06.yang ]]; then
    sysrepoctl --search-dirs /usr/share/velia/yang --install /usr/share/velia/yang/ietf-system@2014-08-06.yang
    sysrepoctl --change ietf-system --permissions 0664 --apply
fi

if [[ ! -f ${REPO}/czechlight-lldp@2020-11-04.yang ]]; then
    if compgen -G "${REPO}/czechlight-lldp@*.yang" >/dev/null; then
        sysrepoctl --search-dirs /usr/share/lldp-systemd-networkd-sysrepo/yang --update /usr/share/lldp-systemd-networkd-sysrepo/yang/czechlight-lldp@2020-11-04.yang
    else
        sysrepoctl --search-dirs /usr/share/lldp-systemd-networkd-sysrepo/yang --install /usr/share/lldp-systemd-networkd-sysrepo/yang/czechlight-lldp@2020-11-04.yang
    fi
    sysrepoctl --change czechlight-lldp --permissions 0664 --apply
fi

if [[ ! -f ${REPO}/czechlight-system@2021-01-13.yang ]]; then
    sysrepoctl --search-dirs /usr/share/velia/yang --install /usr/share/velia/yang/czechlight-system@2021-01-13.yang
    sysrepoctl --change czechlight-system --permissions 0664 --apply
fi

if [[ ! -f ${REPO}/czechlight-firewall@2021-01-25.yang ]]; then
    sysrepoctl --search-dirs /usr/share/velia/yang --install /usr/share/velia/yang/czechlight-firewall@2021-01-25.yang
    sysrepoctl --change czechlight-firewall --permissions 0600 --apply
    sysrepoctl --change ietf-access-control-list --enable-feature eth --enable-feature match-on-eth --enable-feature match-on-ipv4 --enable-feature ipv4 --enable-feature match-on-ipv6 --enable-feature ipv6 --enable-feature mixed-eth-ipv4-ipv6
fi

# If not do not copy here from startup -> running, running might be stale.
sysrepocfg -C startup
