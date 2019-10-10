FROM nvidia/cuda:10.1-runtime

LABEL website="https://github.com/deephealthproject"
LABEL description="DeepHealth European Distributed Deep Learning Library"

RUN \
    echo "\nInstalling software requirements..." >&2 \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -y -q \
    && apt-get install -y --no-install-recommends libopencv-dev \
    && apt-get clean

# set arguments
ARG develop_image
ARG eddl_src_origin="eddl"
ARG ecvl_src_origin="ecvl"
ARG eddl_src_target="/usr/local/src/eddl"
ARG ecvl_src_target="/usr/local/src/ecvl"

# install EDDL library
COPY --from=deephealth-libs-develop ${eddl_src_target}/build/install/lib/* /usr/lib/
COPY --from=deephealth-libs-develop ${eddl_src_target}/build/install/include/third_party/eigen/Eigen /usr/local/include/
COPY --from=deephealth-libs-develop ${eddl_src_target}/build/install/include/* /usr/include/
# install ECVL library
COPY --from=deephealth-libs-develop ${ecvl_src_target}/build/install/lib/* /usr/lib/
COPY --from=deephealth-libs-develop ${ecvl_src_target}/build/install/include/* /usr/include/