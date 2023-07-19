#!/bin/bash

# Import CzechLight-specific NACM rules for DWDM modules
# ------------------------------------------------------
# Before this we restored these NACM rules from our "factory-default" on every boot, overwriting whatever was in the ietf-netconf-acm module.
# Since config v4, the users are free to modify NACM rules as they wish.

sysrepocfg -d startup -m ietf-netconf-acm -f json --import="${MIGRATIONS_DIRECTORY}/0004_nacm.json"
