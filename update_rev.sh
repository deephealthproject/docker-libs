#!/usr/bin/env bash

# Assumes pyecvl repo checked out along with its submodules (recursively) and
# pointing at the relevant pyecvl revision

set -euo pipefail
this="${BASH_SOURCE-$0}"
this_dir=$(cd -P -- "$(dirname -- "${this}")" && pwd -P)

die() {
    echo $1 1>&2
    exit 1
}

nargs=1
if [ $# -ne ${nargs} ]; then
    die "Usage: $0 PYECVL_REPO_DIR"
fi
pyecvl_repo=$1

PYECVL_REVISION=$(git -C "${pyecvl_repo}" rev-parse --short HEAD)
ECVL_REVISION=$(git -C "${pyecvl_repo}"/third_party/ecvl rev-parse --short HEAD)
PYEDDL_REVISION=$(git -C "${pyecvl_repo}"/third_party/pyeddl rev-parse --short HEAD)
EDDL_REVISION=$(git -C "${pyecvl_repo}"/third_party/pyeddl/third_party/eddl rev-parse --short HEAD)

for rev in PYECVL_REVISION ECVL_REVISION PYEDDL_REVISION EDDL_REVISION; do
    sed -i "s/^${rev}=.\+/${rev}=${!rev}/" "${this_dir}"/settings.conf
done
