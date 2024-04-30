#!/bin/bash

# Allow NACM anonymous access user to access ietf-restconf-monitoring module
# --------------------------------------------------------------------------
# Adds rules for the anonymous user access before wildcard deny rule. This runs
# after "0004_nacm" and "0005_nacm_anonymous_user", so if the rule-list itself
# does not exist, we assume that it's a deliberate configuration, and nothing
# gets created. If the rule-list exists, but the deny-all rule does not exist,
# then ietf-restconf-monitoring is simply added as the very last rule.

if RULE=$(sysrepocfg -d startup -G "/ietf-netconf-acm:nacm/rule-list[name='Permit yangnobody user/group to read only some modules']/name") && [ -n "$RULE" ]; then
    if RULE=$(sysrepocfg -d startup -G "/ietf-netconf-acm:nacm/rule-list[name='Permit yangnobody user/group to read only some modules']/rule[name='wildcard-deny']/name") && [ -n "$RULE" ]; then
        sysrepocfg --datastore=startup --format=json --module=ietf-netconf-acm --edit="${MIGRATIONS_DIRECTORY}/0007_nacm_anonymous_user_monitoring.json"
    else
        sysrepocfg --datastore=startup --format=json --module=ietf-netconf-acm --edit="${MIGRATIONS_DIRECTORY}/0007_nacm_anonymous_user_monitoring_append.json"
    fi
fi
