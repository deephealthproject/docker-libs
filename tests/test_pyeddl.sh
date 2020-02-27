#!/bin/bash

# set the path containing sources and tests
PYEDDL_SRC=${PYEDDL_SRC:-"/usr/local/src/pyeddl"}

# run tests
cd ${PYEDDL_SRC} && pytest tests 

# run examples
if [[ $(docker run --gpus 1 nvidia/cuda:10.0-base nvidia-smi) ]]; then
    cd ${PYEDDL_SRC}/examples 
    python3 Tensor/eddl_tensor.py
    bash examples/NN/1_MNIST/run_all_fast.sh
    bash examples/NN/py_loss_metric/run_all_fast.sh
    bash examples/onnx/run_all_fast.sh
fi