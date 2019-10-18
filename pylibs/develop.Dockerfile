FROM deephealth-libs-develop

# set metadata
LABEL website="https://github.com/deephealthproject/"
LABEL description="DeepHealth European Distributed Deep Learning Library"
LABEL version="0.1"

ARG eddl_src="/usr/local/src/eddl"
ARG ecvl_src="/usr/local/src/ecvl"

ARG pyeddl_src_origin="pyeddl"
ARG pyecvl_src_origin="pyecvl"
ARG pyeddl_src_target="/usr/local/src/pyeddl"
ARG pyecvl_src_target="/usr/local/src/pyecvl"

# Run git submodule update [--init] --recursive first
COPY ${pyeddl_src_origin} ${pyeddl_src_target}
COPY ${pyecvl_src_origin} ${pyecvl_src_target}

RUN \
   echo "\nInstalling software requirements..." >&2 \
   && apt-get -y update && apt-get -y install --no-install-recommends \
      python3-dev python3-pip \   
   && apt-get clean \
   && python3 -m pip install --upgrade --no-cache-dir \
      setuptools pip numpy pybind11 pytest

RUN  \
   cd ${pyeddl_src_target} \   
   && echo "\nLinking eddl library..." >&2 \
   && rm -r third_party/eddl \
   && ln -s ${eddl_src} third_party/ \
   && echo "\nInstalling pyeddl module..." >&2 \
   && python3 setup.py install \
   && rm -rf build/temp.*

RUN \
   cd ${pyecvl_src_target} \   
   && echo "\nLinking eddl library..." >&2 \
   && rm -r third_party/ecvl \
   && ln -s ${ecvl_src} third_party/ \
   && echo "\nBuilding pyecvl module..." >&2 \
   && python3 setup.py build_ext -L /usr/lib/gcc/x86_64-linux-gnu/8 \
   && echo "\nInstalling pyecvl module..." >&2 \
   && python3 setup.py install \
   && rm -rf build/temp.*