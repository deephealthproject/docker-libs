#!/bin/bash

# exit on error
set -e

# set the path containing sources and tests
ECVL_SRC=${ECVL_SRC:-"/usr/local/src/ecvl"}
PYECVL_SRC=${PYECVL_SRC:-"/usr/local/src/pyecvl"}

# run tests
cd ${PYECVL_SRC} && pytest tests

# run examples
cd ${PYECVL_SRC}/examples 
bash run_all.sh "${ECVL_SRC}/examples/data"