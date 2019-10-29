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
ECVL_REVISION=ce069064bb49442fc07ba34ed2f66dc8f1ababc1

# PyECVL
PYECVL_REPOSITORY=git@github.com:deephealthproject/pyecvl.git
PYECVL_BRANCH=master
PYECVL_REVISION=ec5357a4274b8561d254a6a750b6eeba404100b4

# EDDL repository 
EDDL_REPOSITORY=git@github.com:deephealthproject/eddl.git
EDDL_BRANCH=develop
EDDL_REVISION=a2e44cdd7ad99ae16aa686aeb72085998cc24557

# PyEDDL repository
PYEDDL_REPOSITORY=git@github.com:deephealthproject/pyeddl.git
PYEDDL_BRANCH=master
PYEDDL_REVISION=f0e7e2c9d0ecbfe065a187465102cf77b6c2fcd6

# date.time as build number
#BUILD_NUMBER ?= $(shell date '+%Y%m%d.%H%M%S')
BUILD_NUMBER = 0.1
