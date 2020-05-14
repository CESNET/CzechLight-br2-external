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

# Dependencies are normally specified via the cla-sysrepo.git repo
${ZUUL_PROJECT_SRC_DIR}/dev-setup-git.sh

if [[ $(jq < ~/zuul-env.json -r '.project.name') != 'CzechLight/br2-external' ]]; then
    TRIGGERED_VIA_DEP=1
else
    TRIGGERED_VIA_DEP=0
fi
BR2_EXTERNAL_COMMIT=$(git --git-dir ${ZUUL_PROJECT_SRC_DIR}/.git rev-parse HEAD)

# If we're being triggered via a change against another repo, use speculatively merged stuff from Zuul, not our submodules
if [[ ${TRIGGERED_VIA_DEP} ]]; then
    # C++ dependencies can be provided either via cla-sysrepo, or via netconf-cli.
    # Whatever is the latest change in the queue wins.
    USE_DEPENDENCIES_VIA=$(jq < ~/zuul-env.json -r '[.items[]? | select(.project.name == "CzechLight/cla-sysrepo" or .project.name == "CzechLight/netconf-cli")][-1]?.project.src_dir + ""')
    if [[ ! -z "${USE_DEPENDENCIES_VIA}" ]]; then
        sed -i "s|${ZUUL_PROJECT_SRC_DIR}/submodules/cla-sysrepo/submodules/dependencies/|${HOME}/${USE_DEPENDENCIES_VIA}/submodules/dependencies/|g" local.mk
        # Our Zuul playbook only prepares submodules within CzechLight/br2-external, not submodules of other projects
        pushd ${HOME}/${USE_DEPENDENCIES_VIA}
        # ...and before we check out, make sure that relative URLs work, i.e,. no file:///dev/null
        git config remote.origin.url $(pwd)
        git submodule update --init --recursive
        git config remote.origin.url file:///dev/null
        popd
    fi

    for PROJECT in cla-sysrepo netconf-cli gammarus; do
        # If there's a change for ${PROJECT} queued ahead, ensure it gets used.
        # This means that if our submodules still pin, say, `cla-sysrepo` to some ancient version and we're testing a `netconf-cli` change,
        # then we will keep using that ancient `cla-sysrepo`. Hopefully this reduces the number of false alerts.
        DEPSRCDIR=$(jq < ~/zuul-env.json -r "[.items[]? | select(.project.name == \"CzechLight/${PROJECT}\")][-1]?.project.src_dir + \"\"")
        if [[ ! -z "${DEPSRCDIR}" ]]; then
            sed -i "s|${ZUUL_PROJECT_SRC_DIR}/submodules/${PROJECT}|${HOME}/${DEPSRCDIR}|g" local.mk
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
make source -j${CI_PARALLEL_JOBS} --output-sync=target

make -j${CI_PARALLEL_JOBS} --output-sync=target rootfs-czechlight-rauc
mv images/update.raucb ~/zuul-output/artifacts/

if [[ "${ZUUL_JOB_NAME}" =~ clearfog ]]; then
    mv images/u-boot-spl.kwb ~/zuul-output/artifacts/

    if [[ ! ${TRIGGERED_VIA_DEP} ]]; then
        # store a cached tarball as an artifact
        ARTIFACT=br2-work-dir-${BR2_EXTERNAL_COMMIT}.tar.zst
        # everything but local.mk which we might have fixed in job prologue
        tar --totals -c \
            .br* \
            build \
            .config \
            host \
            images \
            Makefile \
            per-package \
            staging \
            target \
            | zstd -T0 > ~/zuul-output/artifacts/${ARTIFACT}
    fi
fi

# TODO: USB image as well? (`fallocate -d` to make it sparse)
# TODO: make legal-info
