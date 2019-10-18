FROM deephealth-libs-runtime

# set metadata
LABEL website="https://github.com/deephealthproject/"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL software="deephealth-eddl,deephealth-ecvl,deephealth-pyecvl,deephealth-pyeddl"
LABEL version="0.1"

ARG eddl_src="/usr/local/src/eddl"
ARG ecvl_src="/usr/local/src/ecvl"

ARG pyeddl_src_origin="pyeddl"
ARG pyecvl_src_origin="pyecvl"
ARG pyeddl_src_target="/usr/local/src/pyeddl"
ARG pyecvl_src_target="/usr/local/src/pyecvl"

# Run git submodule update [--init] --recursive first
COPY --from=deephealth-pylibs-develop ${pyeddl_src_target} ${pyeddl_src_target}
COPY --from=deephealth-pylibs-develop ${pyecvl_src_target} ${pyecvl_src_target}

RUN \
   echo "\nInstalling software requirements..." >&2 \
   && apt-get -y update && apt-get -y install --no-install-recommends \
      python3-dev python3-pip \   
   && apt-get clean \
   && python3 -m pip install --upgrade --no-cache-dir \
      setuptools pip numpy pybind11 pytest \
   && cd ${pyeddl_src_target} \   
   && echo "\nInstalling pyeddl module..." >&2 \
   && python3 setup.py install \
   && cd ${pyecvl_src_target} \   
   && echo "\nInstalling pyecvl module..." >&2 \
   && python3 setup.py install