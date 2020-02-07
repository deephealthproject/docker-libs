# base image to start from
ARG BASE_IMAGE
FROM ${BASE_IMAGE} as base

# set metadata
LABEL website="https://github.com/deephealthproject/"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL software="deephealth-eddl,deephealth-ecvl,deephealth-pyecvl,deephealth-pyeddl"
