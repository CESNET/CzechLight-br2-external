#!/bin/bash

if [[ "$(git rev-parse --show-toplevel 2> /dev/null)" = "$(dirname -- "${BASH_SOURCE[0]}")" ]]; then
  echo "Error: run this from a new build directory, not from within the br2-external git repo"
  exit 1
fi

# Configure the local.mk with path to the individual repositories
CZECHLIGHT_BR2_EXT_LOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cat > local.mk <<EOF
DOCOPT_CPP_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/docopt.cpp
REPLXX_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/replxx
CPPCODEC_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/cppcodec
SDBUS_CPP_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/sdbus-cpp

LIBYANG_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/libyang
LIBYANG_CPP_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/libyang-cpp
SYSREPO_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/sysrepo
SYSREPO_CPP_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/sysrepo-cpp
HOST_SYSREPO_POST_RSYNC_HOOKS += HOST_SYSREPO_PATCH_USE_FAKE_DEV_SHM
LIBNETCONF2_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/libnetconf2
NETOPEER2_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/Netopeer2

CLA_SYSREPO_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo
NETCONF_CLI_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/netconf-cli
GAMMARUS_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/gammarus
VELIA_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/velia
ROUSETTE_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/rousette

define CZECHLIGHT_GIT_FIX_GITDIR
	echo "gitdir: \$\$(git rev-parse --resolve-git-dir \$(SRCDIR)/.git)" > \$(@D)/.git
endef
CLA_SYSREPO_POST_RSYNC_HOOKS += CZECHLIGHT_GIT_FIX_GITDIR
NETCONF_CLI_POST_RSYNC_HOOKS += CZECHLIGHT_GIT_FIX_GITDIR
GAMMARUS_POST_RSYNC_HOOKS += CZECHLIGHT_GIT_FIX_GITDIR
VELIA_POST_RSYNC_HOOKS += CZECHLIGHT_GIT_FIX_GITDIR
ROUSETTE_POST_RSYNC_HOOKS += CZECHLIGHT_GIT_FIX_GITDIR

EOF

# We have to run make first so that the proxy Makefile is created and the BR2_EXTERNAL is remembered
make O=$PWD -C ${CZECHLIGHT_BR2_EXT_LOC}/submodules/buildroot BR2_EXTERNAL=${CZECHLIGHT_BR2_EXT_LOC} outputmakefile
