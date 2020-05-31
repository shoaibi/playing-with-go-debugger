#!/usr/bin/env bash

set -o errexit
set -o nounset
set -o pipefail
set -ex

cd "${GOPATH}/src/${APP_NAME}"
exec "$@"