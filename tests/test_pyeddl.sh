#!/bin/bash

PYEDDL_SRC=${PYEDDL_SRC:-"/usr/local/src/pyeddl"}

cd ${PYEDDL_SRC} && pytest tests 
cd ${PYEDDL_SRC}/examples && python3 Tensor/eddl_tensor.py 
cd ${PYEDDL_SRC}/examples && python3 NN/other/eddl_ae.py --epochs 1
