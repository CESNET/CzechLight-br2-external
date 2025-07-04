#!/bin/bash

set -eux -o pipefail
shopt -s failglob

ZUUL_JOB_NAME=$(jq < ~/zuul-env.json -r '.job')
ZUUL_TENANT=$(jq < ~/zuul-env.json -r '.tenant')
ZUUL_GERRIT_HOSTNAME=$(jq < ~/zuul-env.json -r '.project.canonical_hostname')
ZUUL_PROJECT_SRC_DIR=$HOME/$(jq < ~/zuul-env.json -r ".projects[\"${ZUUL_GERRIT_HOSTNAME}/CzechLight/br2-external\"].src_dir")
ZUUL_PROJECT_SHORT_NAME=$(jq < ~/zuul-env.json -r ".projects[\"${ZUUL_GERRIT_HOSTNAME}/CzechLight/br2-external\"].short_name")
CI_PARALLEL_JOBS=$(awk -vcpu=$(getconf _NPROCESSORS_ONLN) 'BEGIN{printf "%.0f", cpu*1.3+1}')
ZUUL_PIPELINE=$(jq < ~/zuul-env.json -r '.pipeline')

BUILD_DIR=~/build
mkdir ${BUILD_DIR}
cd ${BUILD_DIR}

# Dependencies are normally specified via the submodules/dependencies.git repo
${ZUUL_PROJECT_SRC_DIR}/dev-setup-git.sh

if [[ $(jq < ~/zuul-env.json -r '.project.name') != 'CzechLight/br2-external' ]]; then
    TRIGGERED_VIA_DEP=1
else
    TRIGGERED_VIA_DEP=0
fi
BR2_EXTERNAL_COMMIT=$(git --git-dir ${ZUUL_PROJECT_SRC_DIR}/.git rev-parse HEAD)

if [[ "${ZUUL_JOB_NAME}" =~ clearfog ]]; then
    make czechlight_clearfog_defconfig
elif [[ "${ZUUL_JOB_NAME}" =~ beagleboneblack ]]; then
    make czechlight_beaglebone_defconfig
else
    echo "Unrecognized job name, cannot determine defconfig target"
    exit 1
fi

echo BR2_PRIMARY_SITE=\"https://object-store.brno.openstack.cloud.e-infra.cz/swift/v1/KEY_b637b9c937414b29b3e277b4a85cc658/ci-artifacts-public/mirror/buildroot\" >> .config

if [[ ${TRIGGERED_VIA_DEP} == 1 ]]; then
    for PROJECT in cla-sysrepo netconf-cli gammarus velia rousette sysrepo-ietf-alarms; do
        # If there's a change for ${PROJECT} queued ahead, ensure it gets used.
        # This means that if our submodules still pin, say, `cla-sysrepo` to some ancient version and we're testing a `netconf-cli` change,
        # then we will keep using that ancient `cla-sysrepo`. Hopefully this reduces the number of false alerts.
        DEPSRCDIR=$(jq < ~/zuul-env.json -r "[.items[]? | select(.project.name == \"CzechLight/${PROJECT}\")][-1]?.project.src_dir + \"\"")
        if [[ ! -z "${DEPSRCDIR}" ]]; then
            sed -i "s|${ZUUL_PROJECT_SRC_DIR}/submodules/${PROJECT}|${HOME}/${DEPSRCDIR}|g" local.mk
        fi
    done
fi

# Is there a change ahead which updates CzechLight/dependencies? If so, make sure these will get rebuilt.
# This is fragile; if we're triggered via an external module (e.g., `netconf-cli`) and its corresponding change
# depends on a backwards-incompatible update in the NETCONF stack, and the other projects (e.g., `velia`) have not
# been updated yet, this will result in a potentially broken result of the build.
# We cannot simply rebuild all C++ leaf projects either, because we're being triggered one-at-a-time. Since Zuul
# requires (some) build job ordering, there will always be at least one repo which is "too new" for the rest of the leaf projects.
# After a "big" update there should always be a standalone sync to `br2-external` as the very last step anyway.
HAS_CHANGE_OF_DEPENDENCIES=$(jq < ~/zuul-env.json -r '[.items[]? | select(.project.name == "CzechLight/dependencies")][-1]?.project.src_dir + ""')
if [[ ! -z "${HAS_CHANGE_OF_DEPENDENCIES}" ]]; then
    # redirect BR packages to a Zuul-injected dependency
    sed -i "s|${ZUUL_PROJECT_SRC_DIR}/submodules/dependencies|${HOME}/${HAS_CHANGE_OF_DEPENDENCIES}|g" local.mk
fi

# Show exact git versions of what we're going to build
bash <<EOF
    # Extract variables from Makefile into the env
    eval \$(make -E "all:" -pn -f local.mk | grep _OVERRIDE_SRCDIR | sed -E "s/^(.*) = /export \\1=/")
    for PROJ in {libyang,sysrepo,libnetconf2}{,-cpp} netopeer2 cla-sysrepo gammarus netconf-cli rousette sysrepo-ietf-alarms velia; do
        # indirect substitution involves the usual joy in bash
        export PROJ_UCASE=\${PROJ@U}
        export PROJ_DIR=\${PROJ_UCASE//-/_}_OVERRIDE_SRCDIR
        cd \${!PROJ_DIR}
        echo \${PROJ}: \$(git describe --dirty --long --always --tags)
    done
EOF

if [[ ${TRIGGERED_VIA_DEP} == 0 ]]; then
    # Zuul is building a direct change to br2-external. This is by definition the "last change" in the current CI job.
    # There might be other changes for subsequent jobs, but that doesn't matter right now.
    # Ensure that the submodules are already pinned to whatever was provided to Zuul through the `Depends-on` commit footers.
    # In other words, it's an error if we push a change to br2-external which `Depends-on` on a change of some other repo,
    # but that other repo is not explicitly synced in that change to br2-external.
    for PROJECT in dependencies cla-sysrepo gammarus netconf-cli rousette sysrepo-ietf-alarms velia; do
        DEPSRCDIR=$(jq < ~/zuul-env.json -r "[.items[]? | select(.project.name == \"CzechLight/${PROJECT}\")][-1]?.project.src_dir + \"\"")
        if [[ ! -z "${DEPSRCDIR}" ]]; then
            COMMIT_IN_BR2_EXT=$(cd ${ZUUL_PROJECT_SRC_DIR}/submodules/${PROJECT}; git rev-parse HEAD)
            COMMIT_VIA_ZUUL=$(cd ${HOME}/${DEPSRCDIR}; git rev-parse HEAD)
            if [[ ${COMMIT_IN_BR2_EXT} != ${COMMIT_VIA_ZUUL} ]]; then
                echo "br2-external says submodules/${PROJECT} is ${COMMIT_IN_BR2_EXT}, but Zuul prepared ${COMMIT_VIA_ZUUL} instead"
                echo "Last 5 commits in the tree submodules/${PROJECT}"
                GIT_DIR="${ZUUL_PROJECT_SRC_DIR}/submodules/${PROJECT}/.git" git log --oneline -n 5
                echo "Last 5 commits in the tree prepared by Zuul"
                GIT_DIR="${HOME}/${DEPSRCDIR}/.git" git log --oneline -n 5
                exit 1
            fi
        fi
    done
fi

make source -j${CI_PARALLEL_JOBS} --output-sync=target

make -j${CI_PARALLEL_JOBS} --output-sync=target rootfs-czechlight-rauc
mv images/update.raucb ~/zuul-output/artifacts/

make czechlight-cfg-fs-test-migrations

# FIXME: artifact handling is FUBAR
# if [[ "${ZUUL_PIPELINE}" == "tag" ]]; then
if [[ ${TRIGGERED_VIA_DEP} == 0 ]]; then
    # prepare the USB image for flashing
    make -j${CI_PARALLEL_JOBS} all
    mv images/usb-flash.img ~/zuul-output/artifacts/
    # make it sparse in-place
    fallocate -d ~/zuul-output/artifacts/usb-flash.img

    # info about specific versions of packages, their source(s), license, etc
    make -j${CI_PARALLEL_JOBS} legal-info
    XZ_DEFAULTS="-T${CI_PARALLEL_JOBS}" tar -cJf ~/zuul-output/artifacts/legal-info.tar.xz legal-info/

    # for direct boot, aka unbricking the eMMC
    cp host/bin/kwboot ~/zuul-output/artifacts/
fi
