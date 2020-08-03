ARG BASE_IMAGE
FROM ${BASE_IMAGE} as libs.base-toolkit

# set metadata
LABEL website="https://github.com/deephealthproject/" \
      description="DeepHealth European Distributed Deep Learning Library" \
      software="deephealth-eddl,deephealth-ecvl" \
      maintainer="marcoenrico.piras@crs4.it"

# set cmake version
ARG cmake_release="3.18.0"

# set OpenCV version
ARG opencv_release="3.4.9"
ENV OPENCV_RELEASE ${opencv_release}
ENV OPENCV_INSTALL_MANIFEST "/usr/local/opencv/install_manifest.txt"

# set Eigen version
ARG eigen_release="3.3.7"
ENV EIGEN_RELEASE ${eigen_release}
ENV EIGEN_INSTALL_MANIFEST "/usr/local/eigen/install_manifest.txt"
ENV CPATH="/usr/local/include/eigen3:${CPATH}"

# set ProtoBuf version
ARG protobuf_release="3.11.4"
ENV PROTOBUF_RELEASE ${protobuf_release}
ENV PROTOBUF_INSTALL_MANIFEST "/usr/local/protobuf/install_manifest.txt"

# set build target
ARG BUILD_TARGET="CPU"
ENV BUILD_TARGET=${BUILD_TARGET}

# Install software requirements
RUN \
    echo "\nInstalling base software requirements..." >&2 \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -y -q \
    && apt-get install -y --no-install-recommends  \
        build-essential git gcc-8 g++-8 wget rsync graphviz \
        libwxgtk3.0-dev libopenslide-dev zlib1g-dev libblas-dev \
        libavcodec-dev libavformat-dev libswscale-dev \
        libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-7 70 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-7 \
        --slave /usr/bin/x86_64-linux-gnu-gcc x86_64-linux-gnu-gcc /usr/bin/x86_64-linux-gnu-gcc-7 \
        --slave /usr/bin/x86_64-linux-gnu-g++ x86_64-linux-gnu-g++ /usr/bin/x86_64-linux-gnu-g++-7 \
    && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-8 80 \
        --slave /usr/bin/g++ g++ /usr/bin/g++-8 \
        --slave /usr/bin/x86_64-linux-gnu-gcc x86_64-linux-gnu-gcc /usr/bin/x86_64-linux-gnu-gcc-8 \
        --slave /usr/bin/x86_64-linux-gnu-g++ x86_64-linux-gnu-g++ /usr/bin/x86_64-linux-gnu-g++-8 \
    && echo "\n > Installing cmake (version '${cmake_release}')..." >&2 \
    && cd /tmp/ \
    && wget --quiet --no-check-certificate \
        https://github.com/Kitware/CMake/releases/download/v${cmake_release}/cmake-${cmake_release}-Linux-x86_64.tar.gz \
    && tar xzf cmake-${cmake_release}-Linux-x86_64.tar.gz \
    && rm cmake*.tar.gz \
    && mv cmake*/bin/* /usr/local/bin/ \
    && mv cmake*/share/* /usr/local/share/ \
    && chown root:root /usr/local/bin/* /usr/local/share/* \
    && chmod a+rx /usr/local/bin/* \
    && rm -rf /tmp/cmake* \
    && echo "\n > Installing OpenCV (version '${opencv_release}')..." >&2 \
    && cd /tmp/ \
    && wget --quiet --no-check-certificate \
        https://github.com/opencv/opencv/archive/${opencv_release}.tar.gz \
    && tar xzf ${opencv_release}.tar.gz \
    && rm ${opencv_release}.tar.gz \
    && cd opencv-${opencv_release} \
    && mkdir build \
    && cd build \
    && cmake -D CMAKE_BUILD_TYPE=RELEASE \
             -D OPENCV_GENERATE_PKGCONFIG=ON .. \
    && make -j$(nproc) \
    && make install \
    && mkdir -p $(dirname ${OPENCV_INSTALL_MANIFEST}) \
    && cp $(basename ${OPENCV_INSTALL_MANIFEST}) $(dirname ${OPENCV_INSTALL_MANIFEST})/ \
    && rm -rf /tmp/opencv-${opencv_release} \
    # Eigen version installed by APT is too old to work properly with CUDA
    # https://devtalk.nvidia.com/default/topic/1026622/nvcc-can-t-compile-code-that-uses-eigen/
    && echo "\n > Installing Eigen (version '${eigen_release}')..." >&2 \
    && cd /tmp \
    && wget --quiet --no-check-certificate \
        https://gitlab.com/libeigen/eigen/-/archive/${eigen_release}/eigen-${eigen_release}.tar.gz \
    && tar xzf eigen-${eigen_release}.tar.gz \
    && rm eigen-${eigen_release}.tar.gz \
    && cd eigen-${eigen_release} \
    && mkdir build \
    && cd build \
    && cmake -D OpenGL_GL_PREFERENCE=GLVND .. \
    && make install \
    && mkdir -p $(dirname ${EIGEN_INSTALL_MANIFEST}) \
    && cp $(basename ${EIGEN_INSTALL_MANIFEST}) $(dirname ${EIGEN_INSTALL_MANIFEST})/ \
    && rm -rf /tmp/eigen-${eigen_release} \
    && echo "\n > Installing ProtoBuf (version '${protobuf_release}')..." >&2 \
    && cd /tmp \
    && wget --quiet --no-check-certificate \
        https://github.com/protocolbuffers/protobuf/releases/download/v${protobuf_release}/protobuf-all-${protobuf_release}.tar.gz \
    && tar xf protobuf-all-${protobuf_release}.tar.gz \
    && rm protobuf-all-${protobuf_release}.tar.gz \
    && cd protobuf-${protobuf_release}/ \
    && ./configure \
    && make -j$(nproc) \
    && make install \
    && rm -rf /tmp/protobuf-${protobuf_release} \
    && echo "\n > Installing GTest library..." >&2 \
    && apt-get install -y --no-install-recommends libgtest-dev \
    && cd /usr/src/gtest \
    && mkdir build \
    && cd build \
    && cmake .. \
    && make install \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && ldconfig
