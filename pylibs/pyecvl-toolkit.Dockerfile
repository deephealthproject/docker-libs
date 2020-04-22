ARG BASE_IMAGE
FROM ${BASE_IMAGE} as base

# set metadata
LABEL website="https://github.com/deephealthproject/" \
      description="DeepHealth European Distributed Deep Learning Library" \
      software="deephealth-eddl,deephealth-ecvl,deephealth-pyecvl,deephealth-pyeddl"

# set paths
ARG ecvl_src="/usr/local/src/ecvl"
ARG pyecvl_src_origin="pyecvl"
ARG pyeddl_src_target="/usr/local/src/pyeddl"
ARG pyecvl_src_target="/usr/local/src/pyecvl"

# Run git submodule update [--init] --recursive first
COPY ${pyecvl_src_origin} ${pyecvl_src_target}

# build & install
RUN \
   cd ${pyecvl_src_target} \
   && echo "\nLinking ecvl library..." >&2 \
   && rm -r third_party/ecvl \
   && rm -r third_party/pyeddl \
   && ln -s ${ecvl_src} third_party/ecvl \
   && ln -s ${pyeddl_src_target} third_party/pyeddl \
   && echo "\nInstalling pyecvl module..." >&2 \
   && python3 setup.py install --record install.log \
   && rm -rf build/temp.*