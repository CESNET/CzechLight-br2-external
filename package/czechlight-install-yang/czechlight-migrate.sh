#!/bin/bash

set -x

SCRIPT_ROOT=$(dirname $(realpath -s $0))
MIGRATIONS_DIRECTORY=${SCRIPT_ROOT}/migrations
CFG_VERSION_FILE="${CFG_VERSION_FILE:-/cfg/sysrepo/version}"
CFG_STARTUP_FILE="${CFG_STARTUP_FILE:-/cfg/sysrepo/startup.json}"

CLA_YANG="${CLA_YANG:-/usr/share/cla-sysrepo/yang}"
VELIA_YANG="${VELIA_YANG:-/usr/share/velia/yang}"
PROC_CMDLINE="${PROC_CMDLINE:-/proc/cmdline}"

MIGRATION_FILES=(
	'0001_initial-data.sh'
)

for ARG in $(cat "$PROC_CMDLINE"); do
    case "${ARG}" in
        czechlight=*)
            CZECHLIGHT="${ARG:11}"
            ;;
    esac
done

case "${CZECHLIGHT}" in
    sdn-roadm-line*)
        YANG_ROADM=1
        ;;
    sdn-roadm-add-drop*)
        YANG_ROADM=1
        ;;
    sdn-roadm-hires-add-drop*)
        YANG_ROADM=1
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


# we might end up on the system
# * that was created before the migrations were introduced; such system does not have ${CFG_VERSION_FILE}
# * that was just created and freshly initialized with firmware; it has ${CFG_VERSION_FILE} but startup.json does not exist
if [[ -r "${CFG_VERSION_FILE}" && -f "${CFG_STARTUP_FILE}" ]]; then
	VERSION=$(cat "${CFG_VERSION_FILE}")
else
	VERSION=0
fi
[[ "${VERSION}" =~ ^[0-9]+$ ]] || exit 1


while [[ $VERSION -lt ${#MIGRATION_FILES[@]} ]]; do
	. ${SCRIPT_ROOT}/migrations/${MIGRATION_FILES[$VERSION]}
	VERSION=$(($VERSION + 1))
done

# store current version
cat /usr/libexec/czechlight/czechlight-startup-data-version > /cfg/sysrepo/startup_version
