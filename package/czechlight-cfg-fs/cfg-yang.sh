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
    "--install ${ROUSETTE_YANG}/ietf-network-instance@2019-01-21.yang"
    "--install ${ROUSETTE_YANG}/ietf-restconf-subscribed-notifications@2019-11-17.yang"
    "--install ${ROUSETTE_YANG}/ietf-subscribed-notifications@2019-09-09.yang"
)
ALARM_MODULES=(
    "--install ${ALARMS_YANG}/ietf-alarms@2019-09-11.yang"
        "--enable-feature alarm-history"
        "--enable-feature alarm-shelving"
        "--enable-feature alarm-summary"
    "--install ${ALARMS_YANG}/sysrepo-ietf-alarms@2022-02-17.yang"
)
VELIA_MODULES=(
    "--install ${VELIA_YANG}/ietf-system@2014-08-06.yang"
    "--install ${VELIA_YANG}/czechlight-lldp@2020-11-04.yang"
    "--install ${VELIA_YANG}/czechlight-system@2022-07-08.yang"
    "--install ${VELIA_YANG}/iana-if-type@2017-01-19.yang"
    # sysrepoctl doesn't like duplicates, and the ietf-interfaces and
    # ietf-ip modules are now dependencies of ietf-netconf-server
    # "--install ${VELIA_YANG}/ietf-interfaces@2018-02-20.yang"
    # "--install ${VELIA_YANG}/ietf-ip@2018-02-22.yang"
    "--install ${VELIA_YANG}/ietf-routing@2018-03-13.yang"
    "--install ${VELIA_YANG}/ietf-ipv4-unicast-routing@2018-03-13.yang"
    "--install ${VELIA_YANG}/ietf-ipv6-unicast-routing@2018-03-13.yang"
    "--install ${VELIA_YANG}/czechlight-network@2021-02-22.yang"
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
    "--install ${CFG_FS_YANG}/czechlight-netconf-server@2024-09-04.yang"
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
            "--install ${CLA_YANG}/czechlight-roadm-device@2021-03-05.yang"
                "--enable-feature hw-line-9"
        )
        ;;
    sdn-roadm-add-drop-g2)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-roadm-device@2021-03-05.yang"
                "--enable-feature hw-add-drop-20"
        )
        ;;
    sdn-roadm-hires-add-drop-g2)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-roadm-device@2021-03-05.yang"
                "--enable-feature hw-add-drop-20"
                "--enable-feature pre-wss-ocm"
        )
        ;;
    sdn-roadm-coherent-a-d-g2)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-coherent-add-drop@2021-03-05.yang"
        )
        ;;
    sdn-inline-g2)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-inline-amp@2021-03-05.yang"
        )
        ;;
    calibration-box)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-calibration-device@2019-06-25.yang"
        )
        ;;
    sdn-bidi-cplus1572-g2)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-bidi-amp@2022-03-22.yang"
                "--enable-feature dualband-c-plus-1572"
        )
        ;;
    sdn-bidi-cplus1572-ocm-g2)
        CLA_MODULES+=(
            "--install ${CLA_YANG}/czechlight-bidi-amp@2022-03-22.yang"
                "--enable-feature dualband-c-plus-1572"
                "--enable-feature c-band-ocm"
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
