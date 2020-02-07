# base image to start from
ARG BASE_IMAGE
FROM ${BASE_IMAGE} as base

# set metadata
LABEL website="https://github.com/deephealthproject/"
LABEL description="DeepHealth European Distributed Deep Learning Library"

# Install software requirements
RUN \
   echo "\nInstalling software requirements..." >&2 \
   && apt-get -y update && apt-get -y install --no-install-recommends \
      python3-dev python3-pip \   
   && apt-get clean \
   && python3 -m pip install --upgrade --no-cache-dir \
      setuptools pip numpy pybind11 pytest 