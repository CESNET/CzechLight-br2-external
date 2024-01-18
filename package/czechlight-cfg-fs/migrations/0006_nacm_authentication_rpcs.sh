#!/bin/bash

# Enable users change their own pubkeys and password
# --------------------------------------------------
# All users should be able to change their own pubkeys or password.
# We have actions/RPCs for that under /czechlight-system:authentication/users: change-password, add-authorized-key, and authorized-keys/remove

sysrepocfg --datastore=startup --format=json --module=ietf-netconf-acm --edit="${VELIA_YANG}/czechlight-authentication.json"
