#!/bin/bash

set -x

LO=${1:-0}
HI=${2:-9999}

SCRIPT_ROOT=$(dirname $(realpath -s $0))
MIGRATIONS_DIRECTORY=${SCRIPT_ROOT}/migrations

CLA_YANG="${CLA_YANG:-/usr/share/cla-sysrepo/yang}"
VELIA_YANG="${VELIA_YANG:-/usr/share/velia/yang}"
PROC_CMDLINE="${PROC_CMDLINE:-/proc/cmdline}"

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

for file in "${SCRIPT_ROOT}"/migrations/*.sh; do
	set +x
	ORDER=$(basename "$file" | grep -Eo "^[0-9]+" | sed 's/^0*//g')
	if [[ $LO -le $ORDER && $ORDER -le $HI ]]; then
		set -x
		. "$file"
	fi
	set -x
done

