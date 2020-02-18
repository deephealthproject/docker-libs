ARG BASE_IMAGE
FROM ${BASE_IMAGE} as libs.base-toolkit

# set metadata
LABEL website="https://github.com/deephealthproject/"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL software="deephealth-eddl,deephealth-ecvl"

# set cmake version
ARG cmake_release="3.14.6"

# set OpenCV version
ARG opencv_release="3.4.6"
ENV OPENCV_RELEASE ${opencv_release}
ENV OPENCV_INSTALL_MANIFEST "/usr/local/opencv/install_manifest.txt"

# Install software requirements
RUN \
    echo "\nInstalling software requirements..." >&2 \
    && export DEBIAN_FRONTEND=noninteractive \
    && apt-get update -y -q \
    && apt-get install -y --no-install-recommends  \
        build-essential git gcc-8 g++-8 wget rsync graphviz \
        libwxgtk3.0-dev libopenslide-dev \
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
    && apt-get clean \
    && echo "\n > Installing cmake (version '${cmake_release}')..." >&2 \
    && cd /tmp/ \
    && wget --quiet https://github.com/Kitware/CMake/releases/download/v3.14.6/cmake-${cmake_release}-Linux-x86_64.tar.gz \
    && tar xzf cmake-${cmake_release}-Linux-x86_64.tar.gz \
    && rm cmake*.tar.gz \
    && mv cmake*/bin/* /usr/local/bin/ \
    && mv cmake*/share/* /usr/local/share/ \
    && chown root:root /usr/local/bin/* /usr/local/share/* \
    && chmod a+rx /usr/local/bin/* \
    && rm -rf /tmp/cmake* \
    && echo "\n > Installing OpenCV (version '${opencv_release}')..." >&2 \
    && cd /tmp/ \
    && wget --quiet https://github.com/opencv/opencv/archive/${opencv_release}.tar.gz \
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
    && rm -rf /tmp/opencv-${opencv_release}


# && cmake -D CMAKE_BUILD_TYPE=RELEASE \
#              -D INSTALL_C_EXAMPLES=ON \
#              -D OPENCV_GENERATE_PKGCONFIG=ON \
#              -D BUILD_EXAMPLES=ON .. \