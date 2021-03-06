# base image to start from
ARG BASE_IMAGE
FROM ${BASE_IMAGE} as base

# set metadata
LABEL website="https://github.com/deephealthproject/" \
      description="DeepHealth European Distributed Deep Learning Library"

# Install software requirements
RUN \
   echo "\nInstalling software requirements..." >&2 \
   && apt-get -y update && apt-get -y install --no-install-recommends \
      python3-dev python3-pip \   
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/* \
   && python3 -m pip install --upgrade --no-cache-dir \
      pip setuptools \
   && python3 -m pip install --upgrade --no-cache-dir \
      numpy 'pybind11<2.6' pytest
