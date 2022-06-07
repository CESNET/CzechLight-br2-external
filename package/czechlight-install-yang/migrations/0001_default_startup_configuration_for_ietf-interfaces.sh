#!/bin/bash

# setup default configuration for ietf-interfaces in startup DS

if [[ ${YANG_INLINE} == 1 ]]; then
	sysrepocfg --datastore=startup --format=json --module=ietf-interfaces --import="${VELIA_YANG}/ietf-interfaces_sdn-inline.json"
else
	sysrepocfg --datastore=startup --format=json --module=ietf-interfaces --import="${VELIA_YANG}/ietf-interfaces.json"
fi
