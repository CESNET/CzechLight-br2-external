#!/bin/bash

set -x

SCRIPT_ROOT=$(dirname $(realpath -s $0))
MIGRATIONS_DIRECTORY=${SCRIPT_ROOT}/migrations
CFG_VERSION_FILE="${CFG_VERSION_FILE:-/cfg/sysrepo/version}"
CFG_VERSION_FILE_WRITABLE_END="${CFG_VERSION_FILE_WRITABLE_END:-/cfg/sysrepo/version}" # for testing so we dont overwrite test input
CFG_STARTUP_FILE="${CFG_STARTUP_FILE:-/cfg/sysrepo/startup.json}"
CFG_STARTUP_FILE_WRITABLE_END="${CFG_STARTUP_FILE_WRITABLE_END:-/cfg/sysrepo/startup.json}"

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
if [[ -r "$CFG_VERSION_FILE" && -f "$CFG_STARTUP_FILE" ]]; then
	CURRENT_VERSION="$(cat ${CFG_VERSION_FILE})"
else
	CURRENT_VERSION=0
fi
[[ "$CURRENT_VERSION" =~ ^[0-9]+$ ]] || exit 1


set -e

while [[ $CURRENT_VERSION -lt ${#MIGRATION_FILES[@]} ]]; do
	. ${SCRIPT_ROOT}/migrations/${MIGRATION_FILES[$VERSION]}
	CURRENT_VERSION=$(($CURRENT_VERSION + 1))

	# store current version and save startup.json
	echo "$CURRENT_VERSION" > "$CFG_VERSION_FILE_WRITABLE_END"
	sysrepocfg -d startup -f json -X > "$CFG_STARTUP_FILE_WRITABLE_END"

	if [[ "${1:-no-arg}" == "one-step" ]]; then
		break;
	fi
done

