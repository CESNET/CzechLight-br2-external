#!/bin/bash

# Introduce rules for NACM anonymous access user
# ----------------------------------------------
# Adds rules for the anonymous user access to the front of the ietf-netconf-acm:nacm/rule-list.

sysrepocfg --datastore=startup --format=json --module=ietf-netconf-acm --import="${MIGRATIONS_DIRECTORY}/0004_anonymous_nacm.json"
