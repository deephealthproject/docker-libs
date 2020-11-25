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
    wget -q https://www.dropbox.com/s/khrb3th2z6owd9t/mnist_trX.bin
    wget -q https://www.dropbox.com/s/m82hmmrg46kcugp/mnist_trY.bin
    wget -q https://www.dropbox.com/s/7psutd4m4wna2d5/mnist_tsX.bin
    wget -q https://www.dropbox.com/s/q0tnbjvaenb4tjs/mnist_tsY.bin
    python3 examples/NN/1_MNIST/mnist_auto_encoder.py --epochs 1 --small
    rm -fv mnist_*.bin
else
    echo 'Running GPU examples'
    wget -q https://www.dropbox.com/s/khrb3th2z6owd9t/mnist_trX.bin
    wget -q https://www.dropbox.com/s/m82hmmrg46kcugp/mnist_trY.bin
    wget -q https://www.dropbox.com/s/7psutd4m4wna2d5/mnist_tsX.bin
    wget -q https://www.dropbox.com/s/q0tnbjvaenb4tjs/mnist_tsY.bin
    sed -i '/mnist_conv$/d' examples/NN/1_MNIST/run_all_fast.sh
    sed -i '/mnist_losses$/d' examples/NN/1_MNIST/run_all_fast.sh
    bash examples/NN/1_MNIST/run_all_fast.sh
    rm -fv mnist_*.bin
fi
