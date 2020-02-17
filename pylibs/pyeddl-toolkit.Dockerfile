ARG BASE_IMAGE

# base image
FROM ${BASE_IMAGE} as base

# set metadata
LABEL website="https://github.com/deephealthproject/"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL software="deephealth-eddl,deephealth-ecvl,deephealth-pyeddl"

ARG eddl_src="/usr/local/src/eddl"

ARG pyeddl_src_origin="pyeddl"
ARG pyeddl_src_target="/usr/local/src/pyeddl"

# Run git submodule update [--init] --recursive first
COPY ${pyeddl_src_origin} ${pyeddl_src_target}

RUN  \
   cd ${pyeddl_src_target} \
   && echo "\nLinking eddl library..." >&2 \
   && rm -r third_party/eddl \
   && ln -s ${eddl_src} third_party/ \
   && echo "\nInstalling pyeddl module..." >&2 \
   && python3 setup.py install --record install.log \
   && rm -rf build/temp.*
