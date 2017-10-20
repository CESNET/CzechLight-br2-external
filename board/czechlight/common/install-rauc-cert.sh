#!/bin/sh

install -m 0644 -D ${BR2_EXTERNAL_CZECHLIGHT_PATH}/crypto/rauc-cert.pem $TARGET_DIR/etc/rauc/keyring.pem
