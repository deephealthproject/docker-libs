# set docker user credentials
DOCKER_USER=${USER}
DOCKER_PASSWORD=""

# use DockerHub as default registry
DOCKER_REGISTRY=registry.hub.docker.com

# set Docker repository
DOCKER_REPOSITORY_OWNER=${DOCKER_USER}
DOCKER_REPOSITORY_PREFIX=deephealth

# latest tag settings
LATEST_BRANCH=master

# software repositories
ECVL_BRANCH=master
EDDL_BRANCH=master
PYECVL_BRANCH=master
PYEDDL_BRANCH=master
ECVL_REVISION=3b07fabc005c3fca2c7e38cce6502a2d62b61010
EDDL_REVISION=3823f150b22df401f2e7a39bb104454e444ea890
PYECVL_REVISION=791a044127092e31c52617be1ebacb97b9107092
PYEDDL_REVISION=4afab146b38b9de8c89171a16904340e121d6499
ECVL_REPOSITORY=https://github.com/deephealthproject/ecvl.git
EDDL_REPOSITORY=https://github.com/deephealthproject/eddl.git
PYECVL_REPOSITORY=https://github.com/deephealthproject/pyecvl.git
PYEDDL_REPOSITORY=https://github.com/deephealthproject/pyeddl.git

# date.time as build number
#BUILD_NUMBER ?= $(shell date '+%Y%m%d.%H%M%S')