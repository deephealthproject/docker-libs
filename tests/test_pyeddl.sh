#!/bin/bash

# set the path containing sources and tests
PYEDDL_SRC=${PYEDDL_SRC:-"/usr/local/src/pyeddl"}

# run tests
cd ${PYEDDL_SRC} && pytest tests 

# run examples
gpus=$(docker run --runtime=nvidia nvidia/cuda:10.0-base nvidia-smi -L 2>&-)

cd ${PYEDDL_SRC}/examples
if [[ -z ${gpus} ]]; then
    log 'INFO: No GPU available. Running tests with no GPU....'
    log 'Downloading test dataset'
    wget -q  https://www.dropbox.com/s/khrb3th2z6owd9t/trX.bin
	wget -q https://www.dropbox.com/s/m82hmmrg46kcugp/trY.bin
	wget -q https://www.dropbox.com/s/7psutd4m4wna2d5/tsX.bin
	wget -q https://www.dropbox.com/s/q0tnbjvaenb4tjs/tsY.bin
	log 'Running tests....'
    pytest tests
    log 'Running examples....'
	python3 examples/Tensor/array_tensor_save.py
	python3 examples/NN/1_MNIST/mnist_auto_encoder.py --epochs 1
else
    log "Available GPUs: \n ${gpus}"
    log "Running tests..."
    python3 examples/Tensor/array_tensor_save.py
    log 'Running examples....'
    bash examples/NN/1_MNIST/run_all_fast.sh
    bash examples/NN/py_loss_metric/run_all_fast.sh
    bash examples/onnx/run_all_fast.sh
fi