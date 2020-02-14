#!/bin/bash

ECVL_SRC=${ECVL_SRC:-"/usr/local/src/ecvl"}

cd ${ECVL_SRC}/build && ctest -C Debug -VV
