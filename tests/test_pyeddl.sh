#!/bin/bash

# set the path containing sources and tests
PYEDDL_SRC=${PYEDDL_SRC:-"/usr/local/src/pyeddl"}

# run tests
cd ${PYEDDL_SRC} && pytest tests 

# run examples
cd ${PYEDDL_SRC}/examples
if [ -z "${GPU_RUNTIME}" ]; then
    echo 'Downloading test dataset'
    wget -q  https://www.dropbox.com/s/khrb3th2z6owd9t/trX.bin
    wget -q https://www.dropbox.com/s/m82hmmrg46kcugp/trY.bin
    wget -q https://www.dropbox.com/s/7psutd4m4wna2d5/tsX.bin
    wget -q https://www.dropbox.com/s/q0tnbjvaenb4tjs/tsY.bin
    echo 'Running tests for CPUs....'
    pytest tests
    echo 'Running examples....'
    python3 Tensor/array_tensor_save.py
    python3 NN/1_MNIST/mnist_auto_encoder.py --epochs 1
else
    echo "Running tests for GPUs..."
    python3 Tensor/array_tensor_save.py
    echo 'Running examples....'
    bash NN/1_MNIST/run_all_fast.sh
    bash NN/py_loss_metric/run_all_fast.sh
    bash onnx/run_all_fast.sh
fi