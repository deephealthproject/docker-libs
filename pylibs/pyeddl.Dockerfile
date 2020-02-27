# base image to start from
ARG BASE_IMAGE
ARG TOOLKIT_IMAGE

# set toolkit as intermediate stage
FROM ${TOOLKIT_IMAGE} as intermediate_stage

ARG pyeddl_src="/usr/local/src/pyeddl"

WORKDIR ${pyeddl_src}

# merge existing system directories with those containing libraries
RUN sed -e 's+/usr/local/++g' install.log | \
    while IFS= read -r line; do echo ">>> $line" ; rsync --relative "/usr/local/./${line}/" "/intermediate_path/" || exit ; done

# prepare target image
FROM ${BASE_IMAGE} as base

# set metadata
LABEL website="https://github.com/deephealthproject/"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL software="deephealth-eddl,deephealth-ecvl,deephealth-pyeddl"

# enable CUDA support
ENV EDDL_WITH_CUDA 'true'

# Run git submodule update [--init] --recursive first
COPY --from=intermediate_stage /intermediate_path/bin/* /usr/local/bin/
COPY --from=intermediate_stage /intermediate_path/lib/python3.6/dist-packages/* /usr/local/lib/python3.6/dist-packages/

