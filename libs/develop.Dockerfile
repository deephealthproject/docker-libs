FROM nvidia/cuda:10.1-devel

# set metadata
LABEL website="https://github.com/deephealthproject/"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL software="deephealth-eddl,deephealth-ecvl"


ARG cmake_release="3.14.6"
# set arguments
ARG eddl_src_origin="eddl"
ARG ecvl_src_origin="ecvl"
ARG eddl_src_target="/usr/local/src/eddl"
ARG ecvl_src_target="/usr/local/src/ecvl"

# expose lib source paths on environment
ENV EDDL_SRC ${eddl_src_target}
ENV ECVL_SRC ${ecvl_src_target}

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
    && rm -rf /tmp/cmake* \
    && ln -s /usr/lib/x86_64-linux-gnu/libcublas.so /usr/local/cuda/lib64/

# copy libraries
COPY ${ecvl_src_origin} ${ECVL_SRC}
COPY ${eddl_src_origin} ${EDDL_SRC}

# Build and install EDDL library
RUN echo "\nBuilding EDDL library..." >&2 \
    && cd ${EDDL_SRC} \
    && mkdir build \
    && cd build \
    && cmake \
        -D BUILD_TARGET=GPU \
        -D BUILD_TESTS=ON \
        -D EDDL_SHARED=ON \
        .. \
    && make -j$(grep -c ^processor /proc/cpuinfo) \
    && echo "\n Installing EDDL library..." >&2 \
    && make install 

# Build and install ECVL library
RUN echo "\nBuilding ECVL library..." >&2 \
    && cd ${ECVL_SRC} \
    && mkdir build \
    && cd build \
    && cmake \
        -D ECVL_BUILD_GUI=OFF \
        -D ECVL_WITH_OPENSLIDE=ON \
        -D ECVL_DATASET_PARSER=ON \
        -D ECVL_WITH_DICOM=ON \
        -D ECVL_BUILD_EDDL=ON \
        -D EDDL_DIR=${EDDL_SRC}/build/install \
        .. \
    && make -j$(grep -c ^processor /proc/cpuinfo) \
    && echo "\n Installing ECVL library..." >&2 \
    && make install
