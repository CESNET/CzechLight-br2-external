#!/bin/bash

# Import default NACM rules
# -------------------------
# Before this we restored NACM rules from our "factory-default" on every boot.
# This sets them once and admin of the box can change those rules.

sysrepocfg -d startup -m ietf-netconf-acm -f json --import="${MIGRATIONS_DIRECTORY}/0004_nacm.json"
