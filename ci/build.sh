#!/bin/bash

set -eux -o pipefail
shopt -s failglob

ZUUL_JOB_NAME=$(jq < ~/zuul-env.json -r '.job')
ZUUL_PROJECT_SRC_DIR=$HOME/$(jq < ~/zuul-env.json -r '.projects["cesnet-gerrit-czechlight/CzechLight/br2-external"].src_dir')
ZUUL_PROJECT_SHORT_NAME=$(jq < ~/zuul-env.json -r '.projects["cesnet-gerrit-czechlight/CzechLight/br2-external"].short_name')
CI_PARALLEL_JOBS=$(awk -vcpu=$(getconf _NPROCESSORS_ONLN) 'BEGIN{printf "%.0f", cpu*1.3+1}')

BUILD_DIR=~/build
mkdir ${BUILD_DIR}
cd ${BUILD_DIR}

# Dependencies are normally specified by cla-sysrepo
${ZUUL_PROJECT_SRC_DIR}/dev-setup-git.sh

# If we're being triggered via a change against another repo, use speculatively merged stuff from Zuul, not our submodules
if [[ $(jq < ~/zuul-env.json -r '.project.name') != 'CzechLight/br2-external' ]]; then
    # C++ dependencies can be provided either via cla-sysrepo, or via netconf-cli.
    # Whatever is the latest change in the queue wins.
    USE_DEPENDENCIES_VIA=$(jq < ~/zuul-env.json -r '[.items[]? | select(.project.name == "CzechLight/cla-sysrepo" or .project.name == "CzechLight/netconf-cli")][-1]?.project.src_dir + ""')
    if [[ ! -z "${USE_DEPENDENCIES_VIA}" ]]; then
        sed -i "s|\${CZECHLIGHT_BR2_EXT_LOC}/submodules/cla-sysrepo/submodules/dependencies/|${HOME}/${USE_DEPENDENCIES_VIA}/submodules/dependencies/|g" local.mk
    fi

    for PROJECT in cla-sysrepo netconf-cli gammarus; do
        # If there's a change for ${PROJECT} queued ahead, ensure it gets used
        DEPSRCDIR=$(jq < ~/zuul-env.json -r "[.items[]? | select(.project.name == 'CzechLight/${PROJECT}')][-1]?.project.src_dir + ''")
        if [[ ! -z "${DEPSRCDIR}" ]]; then
            sed -i "s|\${CZECHLIGHT_BR2_EXT_LOC}/submodules/${PROJECT}|${HOME}/${DEPSRCDIR}|g"
        fi
    done
fi

if [[ "${ZUUL_JOB_NAME}" =~ clearfog ]]; then
    make czechlight_clearfog_defconfig
elif [[ "${ZUUL_JOB_NAME}" =~ beagleboneblack ]]; then
    make czechlight_beaglebone_defconfig
else
    echo "Unrecognized job name, cannot determine defconfig target"
    exit 1
fi

echo BR2_PRIMARY_SITE=\"https://object-store.cloud.muni.cz/swift/v1/ci-artifacts-public/mirror/buildroot\" >> .config
  # FIXME: remove this
  cat local.mk
  pwd
  ls -al
  sh -c 'set -ex; source local.mk; ls -ald ${CLA_SYSREPO_OVERRIDE_SRCDIR} ${NETCONF_CLI_OVERRIDE_SRCDIR} ${GAMMARUS_OVERRIDE_SRCDIR}'
  exit 6
make source -j${CI_PARALLEL_JOBS} --output-sync=target

make -j${CI_PARALLEL_JOBS} --output-sync=target rootfs-czechlight-rauc
mv images/update.raucb ~/zuul-output/artifacts/

if [[ "${ZUUL_JOB_NAME}" =~ clearfog ]]; then
    mv images/u-boot-spl.kwb ~/zuul-output/artifacts/
fi

# TODO: USB image as well? (`fallocate -d` to make it sparse)
# TODO: make legal-info
