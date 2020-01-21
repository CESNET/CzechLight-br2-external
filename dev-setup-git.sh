#!/bin/bash

if git rev-parse &> /dev/null; then
  echo "Error: run this from a new build directory, not from within a git repo"
  exit 1
fi

# Configure the local.mk with path to the individual repositories
CZECHLIGHT_BR2_EXT_LOC="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cat > local.mk <<EOF
DOCOPT_CPP_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/docopt.cpp
SPDLOG_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/spdlog
REPLXX_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/replxx
CPPCODEC_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/cppcodec
LIBYANG_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/libyang
SYSREPO_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/sysrepo
LIBNETCONF2_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/libnetconf2
NETOPEER2_KEYSTORED_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/Netopeer2
NETOPEER2_SERVER_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/Netopeer2
NETOPEER2_CLI_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/Netopeer2
CLA_SYSREPO_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo
NETCONF_CLI_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/netconf-cli
GAMMARUS_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/gammarus
PYBIND11_OVERRIDE_SRCDIR = ${CZECHLIGHT_BR2_EXT_LOC}/submodules/pybind11
EOF

# We have to run make first so that the proxy Makefile is created and the BR2_EXTERNAL is remembered
make O=$PWD -C ${CZECHLIGHT_BR2_EXT_LOC}/submodules/buildroot BR2_EXTERNAL=${CZECHLIGHT_BR2_EXT_LOC} outputmakefile
