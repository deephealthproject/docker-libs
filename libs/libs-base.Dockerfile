ARG BASE_IMAGE
####################
#### BASE image ####
####################
FROM ${BASE_IMAGE} AS base

LABEL website="https://github.com/deephealthproject"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL software="deephealth-eddl,deephealth-ecvl"

RUN \
    echo "\nInstalling software requirements..." >&2 \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -y -q \
    && apt-get install -y --no-install-recommends \
        wget \
        rsync \
        libopencv-core-dev \
        libopencv-imgproc-dev \
        libopencv-imgcodecs-dev \
        libopenslide-dev \
        libgomp1 \
    && apt-get clean

# create a temp directory
RUN mkdir /tmp/local

# change working directory
WORKDIR /tmp/local