#!/bin/bash

function czechlight_describe_git {
	echo $(git --git-dir=${1}/.git --work-tree=${1} describe --dirty 2>/dev/null || git --git-dir=${1}/.git rev-parse --short HEAD)
}

CACHED_LOCAL_VARS="CLA_SYSREPO_OVERRIDE_SRCDIR NETCONF_CLI_OVERRIDE_SRCDIR GAMMARUS_OVERRIDE_SRCDIR VELIA_OVERRIDE_SRCDIR ROUSETTE_OVERRIDE_SRCDIR SYSREPO_IETF_ALARMS_OVERRIDE_SRCDIR LIBYANG_OVERRIDE_SRCDIR"

pushd ${O}
OVERRIDEN_SOURCES=$(make printvars VARS="${CACHED_LOCAL_VARS}")
popd

function czechlight_query_cached_local_make_var {
	PATTERN="\b$1\b"
	if [[ ! ${CACHED_LOCAL_VARS} =~ ${PATTERN} ]]; then
		echo "Internal error: variable $1 not pre-read from \`make printvars\` in os-release.sh" >&2
		exit 1
	fi
	echo "${OVERRIDEN_SOURCES}" | sed -n -e "s/$1=\\(.*\\)/\\1/p"
}

CLA_BR2_EXTERNAL_REV=$(czechlight_describe_git ${BR2_EXTERNAL_CZECHLIGHT_PATH})
CLA_SYSREPO_REV=$(czechlight_describe_git $(czechlight_query_cached_local_make_var CLA_SYSREPO_OVERRIDE_SRCDIR))
NETCONF_CLI_REV=$(czechlight_describe_git $(czechlight_query_cached_local_make_var NETCONF_CLI_OVERRIDE_SRCDIR))
GAMMARUS_REV=$(czechlight_describe_git $(czechlight_query_cached_local_make_var GAMMARUS_OVERRIDE_SRCDIR))
VELIA_REV=$(czechlight_describe_git $(czechlight_query_cached_local_make_var VELIA_OVERRIDE_SRCDIR))
ROUSETTE_REV=$(czechlight_describe_git $(czechlight_query_cached_local_make_var ROUSETTE_OVERRIDE_SRCDIR))
SYSREPO_IETF_ALARMS_REV=$(czechlight_describe_git $(czechlight_query_cached_local_make_var SYSREPO_IETF_ALARMS_OVERRIDE_SRCDIR))

# CzechLight/dependencies might come either from a git submodule, or from a Zuul change enqueued before this one
CLA_CPP_DEPENDENCIES_REV=$(czechlight_describe_git $(czechlight_query_cached_local_make_var LIBYANG_OVERRIDE_SRCDIR)/..)

sed -i \
	-e 's/^VERSION_ID=/BUILDROOT_VERSION_ID=/' \
	-e 's/^VERSION=/BUILDROOT_VERSION=/' \
	-e '/^NAME=/d' -e '/^PRETTY_NAME=/d' \
	$TARGET_DIR/etc/os-release

cat >> ${TARGET_DIR}/etc/os-release <<EOF
NAME=CzechLight
# When building under CI, these git revisions might not necessarily refer to
# something that is available from Gerrit's git repositories. If the job which
# produced this image is a result of a Zuul job tree with speculatively merged
# changes, then these refs are private to Zuul mergers.
PRETTY_NAME="Czech Light ${CLA_BR2_EXTERNAL_REV}"
VERSION=${CLA_BR2_EXTERNAL_REV}
CLA_SYSREPO_VERSION=${CLA_SYSREPO_REV}
NETCONF_CLI_VERSION=${NETCONF_CLI_REV}
CPP_DEPENDENCIES_VERSION=${CLA_CPP_DEPENDENCIES_REV}
GAMMARUS_VERSION=${GAMMARUS_REV}
VELIA_VERSION=${VELIA_REV}
ROUSETTE_VERSION=${ROUSETTE_REV}
SYSREPO_IETF_ALARMS_VERSION=${SYSREPO_IETF_ALARMS_REV}
EOF
