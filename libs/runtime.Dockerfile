ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS toolkit

####################
#### BASE image ####
####################

FROM nvidia/cuda:10.1-runtime AS base

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
        libopencv-dev \
        libopenslide-dev \
    && apt-get clean

# set arguments
ARG eddl_src_origin="eddl"
ARG ecvl_src_origin="ecvl"
ARG eddl_src_target="/usr/local/src/eddl"
ARG ecvl_src_target="/usr/local/src/ecvl"

#########################
#### INTERMEDIATE Stage ####
#########################
FROM base as prepare_install

# install missing rsync utility
RUN export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -y -q \
    && apt-get install -y --no-install-recommends rsync \
    && apt-get clean

# create a temp directory
RUN mkdir /tmp/local

# make a temporary copy of libraries
COPY --from=toolkit /usr/local/etc /tmp/local/etc
COPY --from=toolkit /usr/local/include /tmp/local/include
COPY --from=toolkit /usr/local/lib /tmp/local/lib
COPY --from=toolkit /usr/local/share /tmp/local/share
COPY --from=toolkit /usr/local/src/ecvl/build/install_manifest.txt /tmp/local/ecvl_manifest.txt
COPY --from=toolkit /usr/local/src/eddl/build/install_manifest.txt /tmp/local/eddl_manifest.txt

# change working directory
WORKDIR /tmp/local

# merge existing system directories with those containing libraries
RUN cat *_manifest.txt >> install_manifest.txt \
    && sed -ie 's+/usr/local/++g' install_manifest.txt \
    && while IFS= read -r line; do echo "--> $line"; rsync --relative "${line}" "/usr/local/"; done < "install_manifest.txt"

######################
#### TARGET Stage ####
######################
FROM base 

# copy libraries to the target paths
COPY --from=prepare_install /usr/local/etc /usr/local/etc
COPY --from=prepare_install /usr/local/include /usr/local/include
COPY --from=prepare_install /usr/local/lib /usr/local/lib
COPY --from=prepare_install /usr/local/share /usr/local/share