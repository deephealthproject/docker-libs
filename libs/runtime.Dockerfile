ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS toolkit

####################
#### BASE image ####
####################

FROM nvidia/cuda:10.1-runtime AS base

LABEL website="https://github.com/deephealthproject"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL software="deephealth-eddl,deephealth-ecvl"
LABEL version="0.1"

RUN \
    echo "\nInstalling software requirements..." >&2 \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -y -q \
    && apt-get install -y --no-install-recommends \
        wget \
        rsync \
        libopencv-dev \
        libopenslide-dev \
    && apt-get clean

# set arguments
ARG eddl_src_origin="eddl"
ARG ecvl_src_origin="ecvl"
ARG eddl_src_target="/usr/local/src/eddl"
ARG ecvl_src_target="/usr/local/src/ecvl"

# install EDDL library
COPY --from=base ${eddl_src_target}/build/install/lib/* /usr/local/lib/
#COPY --from=base ${eddl_src_target}/build/install/include/third_party/eigen/Eigen /usr/local/include/
COPY --from=base ${eddl_src_target}/build/install/include/* /usr/local/include/
# install ECVL library
COPY --from=base ${ecvl_src_target}/build/install/lib/* /usr/local/lib/
COPY --from=base ${ecvl_src_target}/build/install/include/* /usr/local/include/