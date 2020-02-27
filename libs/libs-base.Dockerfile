ARG BASE_IMAGE
ARG TOOLKIT_IMAGE
ARG OPENV_INSTALL_MANIFEST="/usr/local/opencv/install_manifest.txt"

# set toolkit image
FROM ${TOOLKIT_IMAGE} as toolkit

############################
#### INTERMEDIATE Stage ####
############################
FROM ${BASE_IMAGE} AS prepare_install

RUN apt-get update -y -q \
    && apt-get install -y --no-install-recommends wget rsync \
    && apt-get clean

# make a temporary copy of libraries
COPY --from=toolkit /usr/local/bin /tmp/local/bin
COPY --from=toolkit /usr/local/etc /tmp/local/etc
COPY --from=toolkit /usr/local/include /tmp/local/include
COPY --from=toolkit /usr/local/lib /tmp/local/lib
COPY --from=toolkit /usr/local/share /tmp/local/share
COPY --from=toolkit /usr/local/opencv/install_manifest.txt /tmp/local/opencv_manifest.txt
COPY --from=toolkit /usr/local/eigen/install_manifest.txt /tmp/local/eigen_manifest.txt

# merge existing system directories with those containing libraries
RUN cd /tmp/local && sed -e 's+/usr/local/++g' *_manifest.txt | \
    while IFS= read -r line; do echo ">>> $line" ; rsync --relative "${line}" "/usr/local/" || exit ; done \
    && find /tmp/local/lib -not -type d -execdir cp "{}" /usr/local/lib ";"

####################
#### BASE image ####
####################
FROM ${BASE_IMAGE} AS base

LABEL website="https://github.com/deephealthproject"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL software="deephealth-eddl,deephealth-ecvl"

# Install software requirements
RUN \
    echo "\nInstalling software requirements..." >&2 \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -y -q \
    && apt-get install -y --no-install-recommends \
        wget \
        rsync \
        libavcodec-dev libavformat-dev libswscale-dev \
        libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev \
        libopenslide-dev \
        libgomp1 \
    && apt-get clean \
    && ldconfig

# copy libraries to the target paths
COPY --from=prepare_install /usr/local/etc /usr/local/etc
COPY --from=prepare_install /usr/local/include /usr/local/include
COPY --from=prepare_install /usr/local/lib /usr/local/lib
COPY --from=prepare_install /usr/local/share /usr/local/share