#!/bin/bash

set -o errexit
set -o nounset

function usage_error() {
  if [[ $# -ge 1 ]]; then
    echo -e "${@}"
  fi
  printf "Usage: %s NVIDIA_IMG\n" "$0"
  exit 2
}

####### main #######

if [[ $# != 1 ]]; then
  usage_error
fi

NvidiaImage="${1}"

printf "Copying nvidia environment from ${NvidiaImage}\n" >&2

printf "FROM scratch\n"
# We copy the entire environment except for TERM and HOSTNAME
docker run --rm --entrypoint /usr/bin/env "${NvidiaImage}" | \
  sed -n -e '/^TERM=/d; /^HOSTNAME=/d; s/^/ENV /p;'

