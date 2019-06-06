#!/bin/bash

set -eux -o pipefail
shopt -s failglob

ZUUL_JOB_NAME=$(jq < ~/zuul-env.json -r '.job')
ZUUL_PROJECT_SRC_DIR=$HOME/$(jq < ~/zuul-env.json -r '.project.src_dir')
ZUUL_PROJECT_SHORT_NAME=$(jq < ~/zuul-env.json -r '.project.short_name')
CI_PARALLEL_JOBS=$(awk -vcpu=$(getconf _NPROCESSORS_ONLN) 'BEGIN{printf "%.0f", cpu*1.3+1}')

BUILD_DIR=~/build
mkdir ${BUILD_DIR}
cd ${BUILD_DIR}

${ZUUL_PROJECT_SRC_DIR}/dev-setup-git.sh

if [[ "${ZUUL_JOB_NAME}" =~ clearfog ]]; then
    make czechlight_clearfog_defconfig
else
    echo "Unrecognized job name, cannot determine defconfig target"
    exit 1
fi

echo BR2_PRIMARY_SITE=\"https://object-store.cloud.muni.cz/swift/v1/ci-artifacts-public/mirror/buildroot\" >> .config
make source -j${CI_PARALLEL_JOBS} --output-sync=target

# Builds of host-python{,3} often fail in the CI, so let's try to fix that mess
# 1) Build the dependencies as usual
make -j${CI_PARALLEL_JOBS} --output-sync=target host-python-depends host-python3-depends
# 2) Be very careful when building the tools themselves
make host-python host-python3
# 3) Now we're free to resume the build
make -j${CI_PARALLEL_JOBS} --output-sync=target

mv images/update.raucb ~/zuul-output/artifacts/

if [[ "${ZUUL_JOB_NAME}" =~ clearfog ]]; then
    mv images/u-boot-spl.kwb ~/zuul-output/artifacts/
fi

# TODO: USB image as well? (`fallocate -d` to make it sparse)
# TODO: make legal-info
