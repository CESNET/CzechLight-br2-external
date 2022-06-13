#!/bin/bash

# setup default configuration for ietf-interfaces in startup DS

set -x
set -e

# # if user specified some settings, don't overwrite
# if [[ sysrepocfg --datastore=startup --format=json --module=ietf-interfaces | jq '."ietf-interfaces:interfaces"' != "null" ]]; then
# 	exit 0
# fi
if [[ ${YANG_INLINE} == 1 ]]; then
	sysrepocfg --datastore=startup --format=json --module=ietf-interfaces --import="${MIGRATIONS_DIRECTORY}/0002_ietf-interfaces_default-startup-config_sdn-inline.json"
else
	sysrepocfg --datastore=startup --format=json --module=ietf-interfaces --import="${MIGRATIONS_DIRECTORY}/0002_ietf-interfaces_default-startup-config.json"
fi
