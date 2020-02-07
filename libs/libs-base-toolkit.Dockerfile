ARG BASE_IMAGE
FROM ${BASE_IMAGE} as libs.base-toolkit

# set metadata
LABEL website="https://github.com/deephealthproject/"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL software="deephealth-eddl,deephealth-ecvl"

ARG cmake_release="3.14.6"

# Install software requirements
RUN \
    echo "\nInstalling software requirements..." >&2 \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -y -q \
    && apt-get install -y --no-install-recommends  \
        build-essential git gcc-8 g++-8 wget rsync graphviz \
        libopencv-dev libwxgtk3.0-dev libopenslide-dev \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 70 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-7 \
        --slave /usr/bin/x86_64-linux-gnu-gcc x86_64-linux-gnu-gcc /usr/bin/x86_64-linux-gnu-gcc-7 \
        --slave /usr/bin/x86_64-linux-gnu-g++ x86_64-linux-gnu-g++ /usr/bin/x86_64-linux-gnu-g++-7 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 80 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
        --slave /usr/bin/x86_64-linux-gnu-gcc x86_64-linux-gnu-gcc /usr/bin/x86_64-linux-gnu-gcc-8 \
        --slave /usr/bin/x86_64-linux-gnu-g++ x86_64-linux-gnu-g++ /usr/bin/x86_64-linux-gnu-g++-8 \
    && apt-get clean \
    && cd /tmp/ \
    && wget --quiet https://github.com/Kitware/CMake/releases/download/v3.14.6/cmake-${cmake_release}-Linux-x86_64.tar.gz \
    && tar xzf cmake-${cmake_release}-Linux-x86_64.tar.gz \
    && rm cmake*.tar.gz \
    && mv cmake*/bin/* /usr/local/bin/ \
    && mv cmake*/share/* /usr/local/share/ \
    && chown root:root /usr/local/bin/* /usr/local/share/* \
    && chmod a+rx /usr/local/bin/* \
    && rm -rf /tmp/cmake*