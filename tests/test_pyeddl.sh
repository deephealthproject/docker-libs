#!/bin/bash

# set the path containing sources and tests
PYEDDL_SRC=${PYEDDL_SRC:-"/usr/local/src/pyeddl"}

# run tests
cd ${PYEDDL_SRC} && pytest tests 

# run examples
cd ${PYEDDL_SRC}/examples && python3 Tensor/eddl_tensor.py 
cd ${PYEDDL_SRC}/examples && python3 NN/other/eddl_ae.py --epochs 1
