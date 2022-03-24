#!/bin/bash

function czechlight_describe_git {
	echo $(git --git-dir=${1}/.git --work-tree=${1} describe --dirty 2>/dev/null || git --git-dir=${1}/.git rev-parse --short HEAD)
}

function czechlight_query_local_make_var {
	echo $(sed -n -e "s/\\s*$1\\s*=\\s*\\(.*\\)/\\1/p" ${BASE_DIR}/local.mk)
}

CLA_BR2_EXTERNAL_REV=$(czechlight_describe_git ${BR2_EXTERNAL_CZECHLIGHT_PATH})
CLA_SYSREPO_REV=$(czechlight_describe_git $(czechlight_query_local_make_var CLA_SYSREPO_OVERRIDE_SRCDIR))
NETCONF_CLI_REV=$(czechlight_describe_git $(czechlight_query_local_make_var NETCONF_CLI_OVERRIDE_SRCDIR))
CLA_CPP_DEPENDENCIES_REV=$(czechlight_describe_git ${BR2_EXTERNAL_CZECHLIGHT_PATH}/submodules/dependencies)
GAMMARUS_REV=$(czechlight_describe_git $(czechlight_query_local_make_var GAMMARUS_OVERRIDE_SRCDIR))
VELIA_REV=$(czechlight_describe_git $(czechlight_query_local_make_var VELIA_OVERRIDE_SRCDIR))
ROUSETTE_REV=$(czechlight_describe_git $(czechlight_query_local_make_var ROUSETTE_OVERRIDE_SRCDIR))

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
EOF
