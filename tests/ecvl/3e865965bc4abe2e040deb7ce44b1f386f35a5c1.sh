#!/bin/bash

# exit on error
set -e

# set the path containing tests
ECVL_SRC=${ECVL_SRC:-"/usr/local/src/ecvl"}

# install cmake just to run ctest
if [ ! $(command -v cmake) ]; then
    apt-get update -y -q && apt-get install -y -q cmake
fi

# run all tests
cd ${ECVL_SRC}/build && ctest -C Debug -VV
