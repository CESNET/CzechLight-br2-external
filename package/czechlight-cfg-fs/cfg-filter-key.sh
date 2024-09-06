#!/usr/bin/env bash

# This is a standalone script because it's dealing with cleartexts of crypto keys.
# The outer wrapper might run with `set -x` to log each command; this separation ensures
# that we won't leak cleartext keys into the log file.

set -e

PRIVKEY=$(openssl genpkey -algorithm RSA -pkeyopt rsa_keygen_bits:2048 -outform PEM 2>/dev/null | grep -v -- "-----" | tr -d "\n")
sed -e "s|CLEARTEXT_PRIVATE_KEY|\"${PRIVKEY}\"|"
