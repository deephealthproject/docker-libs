#!/bin/bash

# exit on error
set -e

# set the path containing sources and tests
PYEDDL_SRC=${PYEDDL_SRC:-"/usr/local/src/pyeddl"}

# run tests
cd ${PYEDDL_SRC}

echo 'Running tests'
pytest tests

if [ -z "${GPU_RUNTIME}" ]; then
    echo 'Running CPU examples'
    python3 examples/Tensor/array_tensor_save.py
else
    echo 'Running GPU examples'
    python3 examples/Tensor/array_tensor_save.py
fi
