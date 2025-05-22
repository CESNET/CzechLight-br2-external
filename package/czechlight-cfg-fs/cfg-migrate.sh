#!/usr/bin/env bash

set -ex

SCRIPT_ROOT=$(dirname $(realpath -s $0))
CFG_SYSREPO_DIR="${CFG_SYSREPO_DIR:-/cfg/sysrepo}"
CFG_VERSION_FILE=${CFG_SYSREPO_DIR}/version
CFG_STARTUP_FILE=${CFG_SYSREPO_DIR}/startup.json
CFG_STATIC_DATA="${CFG_STATIC_DATA:-/usr/share/yang/static-data/czechlight-cfg-fs}"
VELIA_STATIC_DATA="${VELIA_STATIC_DATA:-/usr/share/yang/static-data/velia}"
CLA_STATIC_DATA="${CLA_STATIC_DATA:-/usr/share/yang/static-data/cla-sysrepo}"
PROC_CMDLINE="${PROC_CMDLINE:-/proc/cmdline}"
CURRENT_VERSION_FILE="${CURRENT_VERSION_FILE:-/usr/libexec/czechlight-cfg-fs/CURRENT_CONFIG_VERSION}"

if [[ -r "${CFG_VERSION_FILE}" && -f "${CFG_STARTUP_FILE}" ]]; then
    OLD_VERSION="$(cat ${CFG_VERSION_FILE})"
else
    OLD_VERSION=0
fi

if [[ ! "$OLD_VERSION" =~ ^[0-9]+$ ]]; then
    echo "Invalid version '${OLD_VERSION}'"
    exit 1
fi

NEW_VERSION=$(cat ${CURRENT_VERSION_FILE})
if (( ${OLD_VERSION} == ${NEW_VERSION} )); then
    exit
elif (( ${OLD_VERSION} > ${NEW_VERSION} )); then
    echo "Attempted to downgrade from ${OLD_VERSION} to ${NEW_VERSION}, that's not supported"
    exit 1
fi

mkdir -p ${CFG_SYSREPO_DIR}
rm -rf ${CFG_SYSREPO_DIR}/old/${OLD_VERSION}
if [[ -f "${CFG_STARTUP_FILE}" ]]; then
    mkdir -p ${CFG_SYSREPO_DIR}/old/${OLD_VERSION}
    cp ${CFG_STARTUP_FILE} /etc/os-release ${CFG_SYSREPO_DIR}/old/${OLD_VERSION}/
fi

# determine which hardware model/variety we're on from /proc/cmdline,
# e.g., there's a "czechlight=sdn-roadm-line-g2" flag passed from the bootloader
for ARG in $(cat "$PROC_CMDLINE"); do
    case "${ARG}" in
        czechlight=*)
            CZECHLIGHT="${ARG##czechlight=}"
            ;;
    esac
done

# busybox' mktemp doesn't know --suffix
DATA_FILE=${DATA_FILE:-$(mktemp -t sr-new-XXXXXX)}

if (( ${OLD_VERSION} < 9 )); then
    V9_MERGE=(
        # NACM rules for anonymous access via RESTCONF and for DWDM permissions
        "${CFG_STATIC_DATA}/nacm.json"
        # do not treat failures in journal upload as system failures
        "${CFG_STATIC_DATA}/alarms-shelve-journal-upload.json"
        # changing one's own passwords/keys
        "${VELIA_STATIC_DATA}/czechlight-authentication.json"
    )

    # NETCONF server configuration
    NETOPEER2_CONFIG=$(mktemp -t sr-nc-XXXXXX)
    ${SCRIPT_ROOT}/cfg-filter-key.sh < ${CFG_STATIC_DATA}/netopeer2.json.in > ${NETOPEER2_CONFIG}
    V9_MERGE+=($NETOPEER2_CONFIG)

    # network configuration as well as optical-specific default config
    case "${CZECHLIGHT}" in
        sdn-roadm-line*)
            V9_MERGE+=(
                "${CLA_STATIC_DATA}/sdn-roadm-line.json"
                "${CFG_STATIC_DATA}/ietf-interfaces-roadm-line.json"
            )
            ;;
        sdn-roadm-add-drop*)
            ;& # fallthrough
        sdn-roadm-hires-add-drop*)
            V9_MERGE+=(
                "${CLA_STATIC_DATA}/sdn-roadm-add-drop.json"
                "${CFG_STATIC_DATA}/ietf-interfaces-roadm-add-drop.json"
            )
            ;;
        sdn-roadm-coherent-a-d*)
            V9_MERGE+=(
                "${CLA_STATIC_DATA}/sdn-roadm-coherent-a-d.json"
                "${CFG_STATIC_DATA}/ietf-interfaces-roadm-add-drop.json"
            )
            ;;
        sdn-inline*)
            V9_MERGE+=(
                "${CLA_STATIC_DATA}/sdn-inline.json"
                "${CFG_STATIC_DATA}/ietf-interfaces-inline-amp.json"
            )
            ;;
        calibration-box)
            V9_MERGE+=(
                "${CLA_STATIC_DATA}/calibration-box.json"
                # no network data on this box
            )
            ;;
    esac

    # libyang v3 mass "migration" means dropping everything, so there's no ${DATA_FILE} as an input
    jq -f ${SCRIPT_ROOT}/meld.jq ${V9_MERGE[@]} > ${DATA_FILE}
elif (( ${OLD_VERSION} < 10 )); then
    # On bidi amplifiers, pump control now has a different syntax (https://gerrit.cesnet.cz/c/CzechLight/cla-sysrepo/+/8755)
    FILTER="."
    for AMP in czechlight-bidi-amp:c-band czechlight-bidi-amp:narrow-1572; do
        # If this amplifier-band block is present, define a whole new content of the "pump" member.
        # Make it a one-leaf dict, either setting the amplifier to "disabled" explicitly, or backporting
        # the pump current.
        FILTER="${FILTER} |
if (has(\"${AMP}\")) then
  .\"${AMP}\".pump =
    if (.\"${AMP}\".pump == \"disabled\") then
        {\"disabled\": [null]}
    else
        {\"manual-current\": .\"${AMP}\".pump}
    end
else
    .
end"
    done
    jq -r "${FILTER}" < ${CFG_STARTUP_FILE} > ${DATA_FILE}
else
    cp ${CFG_STARTUP_FILE} ${DATA_FILE}
fi

cp ${DATA_FILE} ${CFG_STARTUP_FILE}
echo "${NEW_VERSION}" > ${CFG_VERSION_FILE}
