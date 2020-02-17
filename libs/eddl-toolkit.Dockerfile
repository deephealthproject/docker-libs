ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS libs.eddl-toolkit

# set metadata
LABEL website="https://github.com/deephealthproject/"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL software="deephealth-eddl"

# set arguments
ARG eddl_src_origin="eddl"
ARG eddl_src_target="/usr/local/src/eddl"

# expose lib source paths on environment
ENV EDDL_SRC ${eddl_src_target}

# copy libraries
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