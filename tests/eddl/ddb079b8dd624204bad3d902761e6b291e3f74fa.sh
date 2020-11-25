#!/bin/bash

# exit on error
set -e

# set the path containing sources and tests
EDDL_SRC=${EDDL_SRC:-"/usr/local/src/eddl"}

# run all tests
cd ${EDDL_SRC}/build && bin/unit_tests
