ARG BASE_IMAGE
ARG TOOLKIT_IMAGE

# Declare Toolkit image
FROM ${TOOLKIT_IMAGE} AS toolkit

############################
#### INTERMEDIATE Stage ####
############################
FROM ${BASE_IMAGE} AS prepare_install

# set arguments
ARG eddl_src_origin="eddl"
ARG eddl_src_target="/usr/local/src/eddl"

# make a temporary copy of libraries
COPY --from=toolkit /usr/local/etc /tmp/local/etc
COPY --from=toolkit /usr/local/include /tmp/local/include
COPY --from=toolkit /usr/local/lib /tmp/local/lib
COPY --from=toolkit /usr/local/share /tmp/local/share
#COPY --from=toolkit /usr/local/src/ecvl/build/install_manifest.txt /tmp/local/ecvl_manifest.txt
COPY --from=toolkit /usr/local/src/eddl/build/install_manifest.txt /tmp/local/install_manifest.txt

# merge existing system directories with those containing libraries
RUN sed -e 's+/usr/local/++g' install_manifest.txt | \
    while IFS= read -r line; do echo ">>> $line" ; rsync --relative "${line}" "/usr/local/" || exit ; done

######################
#### TARGET Stage ####
######################
FROM ${BASE_IMAGE} AS libs.eddl

# Set metadata
LABEL website="https://github.com/deephealthproject"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL software="deephealth-eddl"

# copy libraries to the target paths
COPY --from=prepare_install /usr/local/etc /usr/local/etc
COPY --from=prepare_install /usr/local/include /usr/local/include
COPY --from=prepare_install /usr/local/lib /usr/local/lib
COPY --from=prepare_install /usr/local/share /usr/local/share