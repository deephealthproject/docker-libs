ARG BASE_IMAGE
FROM ${BASE_IMAGE} AS libs.ecvl-toolkit

# set metadata
LABEL website="https://github.com/deephealthproject/"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL software="deephealth-ecvl"

# set arguments
ARG ecvl_src_origin="ecvl"
ARG ecvl_src_target="/usr/local/src/ecvl"

# expose lib source paths on environment
ENV ECVL_SRC ${ecvl_src_target}

# copy libraries
COPY ${ecvl_src_origin} ${ECVL_SRC}

# Build and install ECVL library
RUN echo "\nBuilding ECVL library..." >&2 \
    && cd ${ECVL_SRC} \
    && mkdir build \
    && cd build \
    && cmake \
        -D ECVL_BUILD_EXAMPLES=ON \
        -D ECVL_BUILD_GUI=OFF \
        -D ECVL_WITH_OPENSLIDE=ON \
        -D ECVL_DATASET_PARSER=ON \
        -D ECVL_WITH_DICOM=ON \
        -D ECVL_BUILD_EDDL=ON \
        -D ECVL_GPU=ON \
        .. \
    && make -j$(grep -c ^processor /proc/cpuinfo) \
    && echo "\n Installing ECVL library..." >&2 \
    && make install \
    && ldconfig
