#!/bin/bash

# exit on error
set -e

# set the path containing sources and tests
PYEDDL_SRC=${PYEDDL_SRC:-"/usr/local/src/pyeddl"}

# run tests
cd ${PYEDDL_SRC}

echo 'Running tests'
pytest tests
