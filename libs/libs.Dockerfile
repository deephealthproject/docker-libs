ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS libs

# Set metadata
LABEL website="https://github.com/deephealthproject"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL software="deephealth-eddl,deephealth-ecvl"
