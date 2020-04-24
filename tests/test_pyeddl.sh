#!/bin/bash

# exit on error
set -e

# set the path containing sources and tests
PYEDDL_SRC=${PYEDDL_SRC:-"/usr/local/src/pyeddl"}

# run tests
cd ${PYEDDL_SRC}

echo 'Downloading test dataset'
wget -q  https://www.dropbox.com/s/khrb3th2z6owd9t/trX.bin
wget -q https://www.dropbox.com/s/m82hmmrg46kcugp/trY.bin
wget -q https://www.dropbox.com/s/7psutd4m4wna2d5/tsX.bin
wget -q https://www.dropbox.com/s/q0tnbjvaenb4tjs/tsY.bin

echo 'Running tests....'
pytest tests

# run examples
if [ -z "${GPU_RUNTIME}" ]; then
    echo 'Running CPU examples...'
    python3 examples/Tensor/array_tensor_save.py
    python3 examples/NN/1_MNIST/mnist_auto_encoder.py --epochs 1
else
    echo "Running GPU examples..."
    python3 examples/Tensor/array_tensor_save.py
    bash examples/NN/1_MNIST/run_all_fast.sh
    bash examples/NN/py_loss_metric/run_all_fast.sh
    bash examples/onnx/run_all_fast.sh
fi