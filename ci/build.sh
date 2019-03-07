#!/bin/bash

set -eux -o pipefail
shopt -s failglob

ZUUL_JOB_NAME=$(jq < ~/zuul-env.json -r '.job')
ZUUL_PROJECT_SRC_DIR=$HOME/$(jq < ~/zuul-env.json -r '.project.src_dir')
ZUUL_PROJECT_SHORT_NAME=$(jq < ~/zuul-env.json -r '.project.short_name')
CI_PARALLEL_JOBS=$(grep -c '^processor' /proc/cpuinfo)

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

echo BR2_PRIMARY_SITE=\"https://ci-logs.gerrit.cesnet.cz/t/public/mirror/buildroot\" >> .config
make source

# host-python fails in parallel build for me with an error in the _hashlib extension
make host-python
# the rest can be built in parallel
sed -i 's/^\(\.NOTPARALLEL\).*/#\1/' ${HOME}/${ZUUL_PROJECT_SRC_DIR}/submodules/buildroot/Makefile
make -j${CI_PARALLEL_JOBS}
mv images/update.raucb ~/zuul-output/artifacts/

if [[ "${ZUUL_JOB_NAME}" =~ clearfog ]]; then
    mv images/u-boot-spl.kwb ~/zuul-output/artifacts/
fi

# TODO: USB image as well? (`fallocate -d` to make it sparse)
# TODO: make legal-info
