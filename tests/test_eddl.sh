#!/bin/bash

EDDL_SRC=${EDDL_SRC:-"/usr/local/src/eddl"}

cd ${EDDL_SRC}/build && ctest -C Debug -VV
