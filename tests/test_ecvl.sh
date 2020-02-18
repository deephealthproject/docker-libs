#!/bin/bash

# set the path containing tests
ECVL_SRC=${ECVL_SRC:-"/usr/local/src/ecvl"}

# install cmake just to run ctest
apt-get update -y -q && apt-get install -y -q cmake

# run all tests
cd ${ECVL_SRC}/build && ctest -C Debug -VV
