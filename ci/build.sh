#!/bin/bash

set -eux -o pipefail
shopt -s failglob

ZUUL_JOB_NAME=$(jq < ~/zuul-env.json -r '.job')
ZUUL_PROJECT_SRC_DIR=$HOME/$(jq < ~/zuul-env.json -r '.project.src_dir')
ZUUL_PROJECT_SHORT_NAME=$(jq < ~/zuul-env.json -r '.project.short_name')

BUILD_DIR=~/build
mkdir ${BUILD_DIR}
cd ${BUILD_DIR}

${ZUUL_PROJECT_SRC_DIR}/dev-setup-git.sh

echo BR2_PRIMARY_SITE=https://ci-logs.gerrit.cesnet.cz/t/public/mirror/buildroot/ >> .config

if [[ "${ZUUL_JOB_NAME}" =~ clearfog ]]; then
    make czechlight_clearfog_defconfig
    make
    mv images/update.raucb images/u-boot-spl.kwb ~/zuul-output/artifacts/
else
    echo "Unrecognized job name, cannot determine defconfig target"
    exit 1
fi

# TODO: USB image as well? (`fallocate -d` to make it sparse)
# TODO: make legal-info
