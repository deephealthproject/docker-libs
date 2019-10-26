# set docker user credentials
DOCKER_USER=deephealth
DOCKER_PASSWORD=""

# use DockerHub as default registry
DOCKER_REGISTRY=registry.hub.docker.com

# set Docker repository
DOCKER_REPOSITORY_OWNER=dhealth
DOCKER_IMAGE_PREFIX=

# latest tag settings
LATEST_BRANCH=master

# ECVL repository
ECVL_REPOSITORY=git@github.com:deephealthproject/ecvl.git
ECVL_BRANCH=master
ECVL_REVISION=3b07fabc005c3fca2c7e38cce6502a2d62b61010

# PyECVL
PYECVL_REPOSITORY=git@github.com:deephealthproject/pyecvl.git
PYECVL_BRANCH=master
PYECVL_REVISION=791a044127092e31c52617be1ebacb97b9107092

# EDDL repository 
EDDL_REPOSITORY=git@github.com:deephealthproject/eddl.git
EDDL_BRANCH=develop
EDDL_REVISION=160de37d300f8b0d7e5f8fddc36c920acf728048

# PyEDDL repository
PYEDDL_REPOSITORY=git@github.com:deephealthproject/pyeddl.git
PYEDDL_BRANCH=master
PYEDDL_REVISION=4afab146b38b9de8c89171a16904340e121d6499

# date.time as build number
#BUILD_NUMBER ?= $(shell date '+%Y%m%d.%H%M%S')
