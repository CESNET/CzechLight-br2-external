#!/bin/bash

# Introduce rules for NACM anonymous access user
# ----------------------------------------------
# Adds rules for the anonymous user access to the front of the ietf-netconf-acm:nacm/rule-list.

sysrepocfg --datastore=startup --format=json --module=ietf-netconf-acm --edit="${MIGRATIONS_DIRECTORY}/0005_nacm_anonymous_user.json"
