#!/bin/bash

# set the path containing tests
EDDL_SRC=${EDDL_SRC:-"/usr/local/src/eddl"}

# install cmake just to run ctest
apt-get update -y -q && apt-get install -y -q cmake

# run all tests
cd ${EDDL_SRC}/build && ctest -C Debug -VV
