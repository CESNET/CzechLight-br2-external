#!/usr/bin/env bash

set -ex

LN2_MODULE_DIR="${LN2_MODULE_DIR:-/usr/share/yang/modules/libnetconf2}"
NP2_MODULE_DIR="${NP2_MODULE_DIR:-/usr/share/yang/modules/netopeer2}"
NETOPEER2_SETUP_DIR="${NETOPEER2_SETUP_DIR:-/usr/libexec/netopeer2}"
CLA_YANG="${CLA_YANG:-/usr/share/yang/modules/cla-sysrepo}"
VELIA_YANG="${VELIA_YANG:-/usr/share/yang/modules/velia}"
ALARMS_YANG="${ALARMS_YANG:-/usr/share/yang/modules/sysrepo-ietf-alarms}"
ROUSETTE_YANG="${ROUSETTE_YANG:-/usr/share/yang/modules/rousette}"
CFG_FS_YANG="${CFG_FS_YANG:-/usr/share/yang/modules/czechlight-cfg-fs}"
PROC_CMDLINE="${PROC_CMDLINE:-/proc/cmdline}"
CFG_SYSREPO_DIR="${CFG_SYSREPO_DIR:-/cfg/sysrepo}"

source ${NETOPEER2_SETUP_DIR}/yang.sh

ROUSETTE_MODULES=(
    "--install ${ROUSETTE_YANG}/ietf-restconf@2017-01-26.yang"
    "--install ${ROUSETTE_YANG}/ietf-restconf-monitoring@2017-01-26.yang"
    "--install ${ROUSETTE_YANG}/ietf-yang-patch@2017-02-22.yang"
    "--install ${ROUSETTE_YANG}/ietf-restconf-subscribed-notifications@2019-11-17.yang"
)

# The "ietf-subscribed-notifications" YANG module is already installed by netopeer2, but without
# the "encode-json" feature enabled, so we have to monkey-patch that in.
NETOPEER2_YANG_SETUP_COUNT=${#NETOPEER2_YANG_SETUP[@]}
IETF_SUBSCIBED_NOTIFICATIONS_JSON=0
for (( i=1; i<$NETOPEER2_YANG_SETUP_COUNT; i++ )); do
    if [[ ${NETOPEER2_YANG_SETUP[i]} =~ "/ietf-subscribed-notifications@" ]]; then
        NETOPEER2_YANG_SETUP=(
            "${NETOPEER2_YANG_SETUP[@]:0:i+1}"
            "--enable-feature encode-json"
            "${NETOPEER2_YANG_SETUP[@]:i+1}"
        )
        IETF_SUBSCIBED_NOTIFICATIONS_JSON=1
        break
    fi
done
if [[ ${IETF_SUBSCIBED_NOTIFICATIONS_JSON} == 0 ]]; then
    echo "YANG script error: cannot enable 'encode-json' for ietf-subscribed-notifications"
    exit 1
fi

ALARM_MODULES=(
    "--install ${ALARMS_YANG}/ietf-alarms@2019-09-11.yang"
        "--enable-feature alarm-history"
        "--enable-feature alarm-shelving"
        "--enable-feature alarm-summary"
    "--install ${ALARMS_YANG}/sysrepo-ietf-alarms@2022-02-17.yang"
)
VELIA_MODULES=(
    "--install ${VELIA_YANG}/ietf-system@2014-08-06.yang"
    "--install ${VELIA_YANG}/czechlight-lldp@2026-01-09.yang"
    "--install ${VELIA_YANG}/czechlight-system@2022-07-08.yang"
    "--install ${VELIA_YANG}/iana-if-type@2017-01-19.yang"
    # sysrepoctl doesn't like duplicates, and the ietf-interfaces and
    # ietf-ip modules are now dependencies of ietf-netconf-server
    # "--install ${VELIA_YANG}/ietf-interfaces@2018-02-20.yang"
    # "--install ${VELIA_YANG}/ietf-ip@2018-02-22.yang"
    "--install ${VELIA_YANG}/ietf-routing@2018-03-13.yang"
    "--install ${VELIA_YANG}/ietf-ipv4-unicast-routing@2018-03-13.yang"
    "--install ${VELIA_YANG}/ietf-ipv6-unicast-routing@2018-03-13.yang"
    "--install ${VELIA_YANG}/ietf-rib-extension@2023-11-20.yang"
    "--install ${VELIA_YANG}/czechlight-network@2025-06-06.yang"
    "--install ${VELIA_YANG}/ietf-access-control-list@2019-03-04.yang"
        "--enable-feature match-on-eth"
        "--enable-feature eth"
        "--enable-feature match-on-ipv4"
        "--enable-feature ipv4"
        "--enable-feature match-on-ipv6"
        "--enable-feature ipv6"
        "--enable-feature mixed-eth-ipv4-ipv6"
    "--install ${VELIA_YANG}/czechlight-firewall@2021-01-25.yang"
    "--install ${VELIA_YANG}/velia-alarms@2022-07-12.yang"
)
CFG_FS_MODULES=(
    "--install ${CFG_FS_YANG}/czechlight-netconf-server@2025-12-01.yang"
)
CLA_MODULES=(
    "--install ${CLA_YANG}/iana-hardware@2018-03-13.yang"
    "--install ${CLA_YANG}/ietf-hardware@2018-03-13.yang"
        "--enable-feature hardware-sensor"
        "--enable-feature hardware-state"
)

# determine which hardware model/variety we're on from /proc/cmdline,
# e.g., there's a "czechlight=sdn-roadm-line-g2" flag passed from the bootloader
for ARG in $(cat "$PROC_CMDLINE"); do
    case "${ARG}" in
        czechlight=*)
            CZECHLIGHT="${ARG##czechlight=}"
            ;;
    esac
done

case "${CZECHLIGHT}" in
    "")
        # no device model set -> do nothing
        ;;
    sdn-roadm-line-g2)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-roadm-common@2021-03-05.yang"
            "--install ${CLA_YANG}/czechlight-roadm-device@2025-11-24.yang"
                "--enable-feature hw-line-9"
        )
        VELIA_MODULES+=(
            "--install ${VELIA_YANG}/czechlight-network-sdn-roadm-line@2025-06-06.yang"
        )
        ;;
    sdn-roadm-add-drop-g2)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-roadm-common@2021-03-05.yang"
            "--install ${CLA_YANG}/czechlight-roadm-device@2025-11-24.yang"
                "--enable-feature hw-add-drop-20"
        )
        VELIA_MODULES+=(
            "--install ${VELIA_YANG}/czechlight-network-sdn-generic@2025-06-06.yang"
        )
        ;;
    sdn-roadm-hires-add-drop-g2)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-roadm-common@2021-03-05.yang"
            "--install ${CLA_YANG}/czechlight-roadm-device@2025-11-24.yang"
                "--enable-feature hw-add-drop-20"
                "--enable-feature pre-wss-ocm"
        )
        VELIA_MODULES+=(
            "--install ${VELIA_YANG}/czechlight-network-sdn-generic@2025-06-06.yang"
        )
        ;;
    sdn-roadm-coherent-a-d-g2)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-coherent-add-drop@2025-11-24.yang"
        )
        VELIA_MODULES+=(
            "--install ${VELIA_YANG}/czechlight-network-sdn-generic@2025-06-06.yang"
        )
        ;;
    sdn-inline-g2)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-inline-amp@2021-03-05.yang"
        )
        VELIA_MODULES+=(
            "--install ${VELIA_YANG}/czechlight-network-sdn-inline@2025-06-06.yang"
        )
        ;;
    calibration-box)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-calibration-device@2019-06-25.yang"
        )
        ;;
    sdn-bidi-cplus1572-g2)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-bidi-amp@2025-05-22.yang"
                "--enable-feature dualband-c-plus-1572"
        )
        VELIA_MODULES+=(
            "--install ${VELIA_YANG}/czechlight-network-sdn-generic@2025-06-06.yang"
        )
        ;;
    sdn-bidi-cplus1572-ocm-g2)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-bidi-amp@2025-05-22.yang"
                "--enable-feature dualband-c-plus-1572"
                "--enable-feature c-band-ocm"
        )
        VELIA_MODULES+=(
            "--install ${VELIA_YANG}/czechlight-network-sdn-generic@2025-06-06.yang"
        )
        ;;
    *)
        echo "Error: unsupported CzechLight device model ${CZECHLIGHT}"
        exit 1
        ;;
esac

sysrepoctl \
    -v2 \
    --search-dirs ${NP2_MODULE_DIR}:${CLA_YANG}:${VELIA_YANG}:${ALARMS_YANG}:${ROUSETTE_YANG} \
    ${NETOPEER2_YANG_SETUP[@]} \
    ${ROUSETTE_MODULES[@]} \
    ${ALARM_MODULES[@]} \
    ${VELIA_MODULES[@]} \
    ${CFG_FS_MODULES[@]} \
    ${CLA_MODULES[@]} \
    --init-data ${CFG_SYSREPO_DIR}/startup.json
