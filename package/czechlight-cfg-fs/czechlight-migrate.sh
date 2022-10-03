#!/bin/bash

set -ex

SCRIPT_ROOT=$(dirname $(realpath -s $0))
MIGRATIONS=$SCRIPT_ROOT/czechlight-migration-list.sh
export MIGRATIONS_DIRECTORY=${SCRIPT_ROOT}/migrations
CFG_VERSION_FILE="${CFG_VERSION_FILE:-/cfg/sysrepo/version}"
CFG_STARTUP_FILE="${CFG_STARTUP_FILE:-/cfg/sysrepo/startup.json}"
PROC_CMDLINE="${PROC_CMDLINE:-/proc/cmdline}"

export CLA_YANG="${CLA_YANG:-/usr/share/cla-sysrepo/yang}"
export VELIA_YANG="${VELIA_YANG:-/usr/share/velia/yang}"
export ALARMS_YANG="${ALARMS_YANG:-/usr/share/sysrepo-ietf-alarms/yang}"

# load migrations and perform a sanity check (filename's numerical prefix corresponds to the order in the MIGRATIONS array)
source $MIGRATIONS
for i in $(seq ${#MIGRATION_FILES[@]}); do
    FILENAME=${MIGRATION_FILES[$(($i - 1))]}

    if ! [[ "$FILENAME" =~ ^[0-9]{4}_.*.sh$ ]]; then
        echo "Migration file '$FILENAME' has unexpected name"
        exit 1
    fi

    FILE_REV=$(echo "$FILENAME" | grep -Eo "^[0-9]{4}")
    if [[ $((FILE_REV + 0)) != $i ]]; then
        echo "Migration filename '$FILENAME' hints revision $(($FILE_REV + 0)) but it is at position $i of the migration array"
        exit 1
    fi
done

for ARG in $(cat "$PROC_CMDLINE"); do
    case "${ARG}" in
        czechlight=*)
            export CZECHLIGHT="${ARG:11}"
            ;;
    esac
done

case "${CZECHLIGHT}" in
    sdn-roadm-line*)
        export YANG_ROADM=1
        ;;
    sdn-roadm-add-drop*)
        export YANG_ROADM=1
        ;;
    sdn-roadm-hires-add-drop*)
        export YANG_ROADM=1
        ;;
    sdn-roadm-coherent-a-d*)
        export YANG_COHERENT=1
        ;;
    sdn-inline*)
        export YANG_INLINE=1
        ;;
    calibration-box)
        export YANG_CALIBRATION=1
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

if [[ ! "$CURRENT_VERSION" =~ ^[0-9]+$ ]]; then
    echo "Invalid version '$CURRENT_VERSION'"
    exit 1
fi

while [[ $CURRENT_VERSION -lt ${#MIGRATION_FILES[@]} ]]; do
    /bin/bash ${SCRIPT_ROOT}/migrations/${MIGRATION_FILES[$CURRENT_VERSION]}
    CURRENT_VERSION=$(($CURRENT_VERSION + 1))
done

# store current version and save startup.json
mkdir -p $(dirname ${CFG_STARTUP_FILE}) $(dirname ${CFG_VERSION_FILE})
sysrepocfg -d startup -f json -X > "$CFG_STARTUP_FILE"
echo "$CURRENT_VERSION" > "$CFG_VERSION_FILE"

# If not do not copy here from startup -> running, running might be stale.
sysrepocfg -C startup
