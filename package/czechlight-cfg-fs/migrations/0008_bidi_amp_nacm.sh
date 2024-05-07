#!/bin/bash
set -ex

# Configure access to the czechlight-bidi-amp module
# --------------------------------------------------
#
# The rules are added right after those for the inline amplifier. Since this script only runs after "0004_nacm"
# and "0005_nacm_anonymous_user", we can assume that if the outer rule-list is not present at all, that must be
# a deliberate configuration. In that case, we probably should not add any rules. Similarly, if there's no rule
# for the "czechlight-inline-amp", let's take a guess and assume that the operator does not want to allow access
# to amplifiers -- again, it can only happen due to an explicit configuration.
#
# The first rule is for authenticated users, default group "dwdm".
if RULE=$(sysrepocfg -d startup -G "/ietf-netconf-acm:nacm/rule-list[name='Allow DWDM control to the optics group']/rule[name='czechlight-inline-amp']/name") \
    && [ "$RULE" == "czechlight-inline-amp" ]; then
    sysrepocfg --datastore=startup --format=json --module=ietf-netconf-acm --edit="${MIGRATIONS_DIRECTORY}/0008_bidi_amp_nacm_optics.json"
fi

# The second rule allows anonymous read-only access via RESTCONF.
if RULE=$(sysrepocfg -d startup -G "/ietf-netconf-acm:nacm/rule-list[name='Permit yangnobody user/group to read only some modules']/rule[name='czechlight-inline-amp']/name") \
    && [ "$RULE" == "czechlight-inline-amp" ]; then
    sysrepocfg --datastore=startup --format=json --module=ietf-netconf-acm --edit="${MIGRATIONS_DIRECTORY}/0008_bidi_amp_nacm_anonymous_user.json"
fi
