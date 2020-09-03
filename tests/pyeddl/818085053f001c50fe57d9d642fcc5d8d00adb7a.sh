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
    python3 examples/NN/1_MNIST/mnist_auto_encoder.py --small --epochs 1
else
    echo "Running GPU examples..."
    python3 examples/Tensor/array_tensor_save.py
    # replace `bash examples/NN/1_MNIST/run_all_fast.sh`
    # with explicit call the example passing the "--small" when allowed
    python3 examples/NN/1_MNIST/mnist_auto_encoder.py --small --gpu --epochs 1
    python3 examples/NN/1_MNIST/mnist_conv.py --gpu --epochs 1
    python3 examples/NN/1_MNIST/mnist_losses.py --gpu --epochs 1
    python3 examples/NN/1_MNIST/mnist_mlp_da.py --gpu --epochs 1
    python3 examples/NN/1_MNIST/mnist_mlp_initializers.py --gpu --epochs 1
    python3 examples/NN/1_MNIST/mnist_mlp.py --gpu --epochs 1
    python3 examples/NN/1_MNIST/mnist_mlp_regularizers.py --gpu --epochs 1
    python3 examples/NN/1_MNIST/mnist_mlp_train_batch.py --gpu --epochs 1
    python3 examples/NN/1_MNIST/mnist_rnn.py --gpu --epochs 1
    bash examples/NN/py_loss_metric/run_all_fast.sh
    bash examples/onnx/run_all_fast.sh
fi
