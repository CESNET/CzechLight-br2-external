#!/bin/bash

if [[ "$(git rev-parse --show-toplevel 2> /dev/null)" = "$(dirname -- "${BASH_SOURCE[0]}")" ]]; then
  echo "Error: run this from a new build directory, not from within the br2-external git repo"
  exit 1
fi

# Configure the local.mk with path to the individual repositories
CZECHLIGHT_BR2_EXT_LOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cat > local.mk <<EOF
REPLXX_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/dependencies/replxx
SDBUS_CPP_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/dependencies/sdbus-cpp

LIBYANG_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/dependencies/libyang
LIBYANG_CPP_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/dependencies/libyang-cpp
SYSREPO_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/dependencies/sysrepo
SYSREPO_CPP_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/dependencies/sysrepo-cpp
HOST_SYSREPO_POST_RSYNC_HOOKS += HOST_SYSREPO_PATCH_USE_FAKE_DEV_SHM
LIBNETCONF2_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/dependencies/libnetconf2
LIBNETCONF2_CPP_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/dependencies/libnetconf2-cpp
NETOPEER2_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/dependencies/Netopeer2

CLA_SYSREPO_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo
NETCONF_CLI_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/netconf-cli
GAMMARUS_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/gammarus
VELIA_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/velia
ROUSETTE_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/rousette
SYSREPO_IETF_ALARMS_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/sysrepo-ietf-alarms

define CZECHLIGHT_GIT_FIX_GITDIR
	echo "gitdir: \$\$(git rev-parse --resolve-git-dir \$(SRCDIR)/.git)" > \$(@D)/.git
endef
CZECHLIGHT_HACK_GIT_DIR = GIT_DIR=.git
CLA_SYSREPO_POST_RSYNC_HOOKS += CZECHLIGHT_GIT_FIX_GITDIR
CLA_SYSREPO_BUILD_ENV += \$(CZECHLIGHT_HACK_GIT_DIR)
NETCONF_CLI_POST_RSYNC_HOOKS += CZECHLIGHT_GIT_FIX_GITDIR
NETCONF_CLI_BUILD_ENV += \$(CZECHLIGHT_HACK_GIT_DIR)
GAMMARUS_POST_RSYNC_HOOKS += CZECHLIGHT_GIT_FIX_GITDIR
GAMMARUS_BUILD_ENV += \$(CZECHLIGHT_HACK_GIT_DIR)
VELIA_POST_RSYNC_HOOKS += CZECHLIGHT_GIT_FIX_GITDIR
VELIA_BUILD_ENV += \$(CZECHLIGHT_HACK_GIT_DIR)
ROUSETTE_POST_RSYNC_HOOKS += CZECHLIGHT_GIT_FIX_GITDIR
ROUSETTE_BUILD_ENV += \$(CZECHLIGHT_HACK_GIT_DIR)
SYSREPO_IETF_ALARMS_POST_RSYNC_HOOKS += CZECHLIGHT_GIT_FIX_GITDIR
SYSREPO_IETF_ALARMS_BUILD_ENV += \$(CZECHLIGHT_HACK_GIT_DIR)

EOF

# We have to run make first so that the proxy Makefile is created and the BR2_EXTERNAL is remembered
make O=$PWD -C ${CZECHLIGHT_BR2_EXT_LOC}/submodules/buildroot BR2_EXTERNAL=${CZECHLIGHT_BR2_EXT_LOC} outputmakefile
