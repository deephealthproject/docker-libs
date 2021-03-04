ARG BASE_IMAGE

# base image
FROM ${BASE_IMAGE} as base

# set metadata
LABEL website="https://github.com/deephealthproject/" \
      description="DeepHealth European Distributed Deep Learning Library" \
      software="deephealth-eddl,deephealth-ecvl,deephealth-pyeddl"

ARG eddl_src="/usr/local/src/eddl"

ARG pyeddl_src_origin="pyeddl"
ARG pyeddl_src_target="/usr/local/src/pyeddl"

# Run git submodule update [--init] --recursive first
COPY ${pyeddl_src_origin} ${pyeddl_src_target}

# Update path to dynamic/shared
ENV LD_LIBRARY_PATH="/usr/local/cuda-10.1/targets/x86_64-linux/lib:${LD_LIBRARY_PATH}"

# link the cudart, cublas and curand libraries on "standard" system locations
# FIXME: EDDL_WITH_CUDA should also be exported for CUDNN build target
#   however, it seems to work even though it's not being exported
RUN /bin/bash -c "if [[ \"${BUILD_TARGET}\" == \"GPU\" ]]; then \
      export EDDL_WITH_CUDA=\"true\" ; \
    fi" \
    && cd ${pyeddl_src_target} \
    && echo "\nLinking eddl library..." >&2 \
    && rm -rf third_party/eddl \
    && ln -s ${eddl_src} third_party/ \
    && echo "\nInstalling pyeddl module..." >&2 \
    && python3 setup.py build_ext -L /usr/local/cuda-10.1/targets/x86_64-linux/lib \
    && python3 setup.py install --record install.log \
    && rm -rf build/temp.*
