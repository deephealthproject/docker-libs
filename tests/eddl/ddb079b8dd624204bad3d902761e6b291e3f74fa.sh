#!/bin/bash

# exit on error
set -e

# set the path containing sources and tests
EDDL_SRC=${EDDL_SRC:-"/usr/local/src/eddl"}

# install cmake just to run ctest
if [ ! $(command -v cmake) ]; then
    apt-get update -y -q && apt-get install -y -q cmake
fi

# run all tests
cd ${EDDL_SRC}/build && ctest -C Debug -VV
