#!/bin/bash

# Allow NACM anonymous access user to access ietf-restconf-monitoring module
# --------------------------------------------------------------------------
# Adds rules for the anonymous user access before wildcard deny rule
# if the rule-list for anonymous user, or the deny-all rule doesn't exist,
# then just append the rule to the end of the list or create the rule-list.

if WILDCARD_DENY_RULE_QUERY=$(sysrepocfg -d startup -G "/ietf-netconf-acm:nacm/rule-list[name='Permit yangnobody user/group to read only some modules']/rule[name='wildcard-deny']/name") \
    && [ "$WILDCARD_DENY_RULE_QUERY" == "wildcard-deny" ]; then
    sysrepocfg --datastore=startup --format=json --module=ietf-netconf-acm --edit="${MIGRATIONS_DIRECTORY}/0007_nacm_anonymous_user_monitoring.json"
else
    sysrepocfg --datastore=startup --format=json --module=ietf-netconf-acm --edit="${MIGRATIONS_DIRECTORY}/0007_nacm_anonymous_user_monitoring_append.json"
fi
