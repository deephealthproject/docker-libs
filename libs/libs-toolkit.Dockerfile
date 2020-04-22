ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS libs-toolkit

# set metadata
LABEL website="https://github.com/deephealthproject/" \
      description="DeepHealth European Distributed Deep Learning Library" \
      software="deephealth-eddl,deephealth-ecvl"