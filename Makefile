# version
VERSION ?= 1.0

# set docker user credentials
DOCKER_USER ?= ${USER}
DOCKER_PASSWORD ?= ${DOCKER_PASSWORD}

# use DockerHub as default registry
DOCKER_REGISTRY ?= registry.hub.docker.com

# set Docker repository
DOCKER_REPOSITORY_OWNER ?= ${DOCKER_USER}
DOCKER_REPOSITORY_PREFIX ?= deephealth

# latest tag settings
LATEST_BRANCH ?= master


LOCAL_LIBS_PATH ?= libs
LOCAL_PYLIBS_PATH ?= pylibs
ECVL_LIB_PATH = ${LOCAL_LIBS_PATH}/ecvl
EDDL_LIB_PATH = ${LOCAL_LIBS_PATH}/eddl
PYECVL_LIB_PATH = ${LOCAL_PYLIBS_PATH}/pyecvl
PYEDDL_LIB_PATH = ${LOCAL_PYLIBS_PATH}/pyeddl

# software repositories
ECVL_BRANCH ?= master
EDDL_BRANCH ?= master
PYECVL_BRANCH ?= master
PYEDDL_BRANCH ?= master
ECVL_REVISION ?= 3b07fabc005c3fca2c7e38cce6502a2d62b61010
EDDL_REVISION ?= 3823f150b22df401f2e7a39bb104454e444ea890
PYECVL_REVISION ?= 791a044127092e31c52617be1ebacb97b9107092
PYEDDL_REVISION ?= 4afab146b38b9de8c89171a16904340e121d6499
ECVL_REPOSITORY ?= https://github.com/deephealthproject/ecvl.git
EDDL_REPOSITORY ?= https://github.com/deephealthproject/eddl.git
PYECVL_REPOSITORY ?= https://github.com/deephealthproject/pyecvl.git
PYEDDL_REPOSITORY ?= https://github.com/deephealthproject/pyeddl.git

# enable latest tags
push_latest_tags=false
ifeq (${LATEST_BRANCH}, ${ECVL_BRANCH})
ifeq (${LATEST_BRANCH}, ${EDDL_BRANCH})
	push_latest_tags = true
endif
endif

# set no cache option
DISABLE_CACHE ?= 
BUILD_CACHE_OPT ?= 
ifneq ("$(DISABLE_CACHE)", "")
BUILD_CACHE_OPT = --no-cache
endif

# date.time as build number
BUILD_NUMBER ?= $(shell date '+%Y%m%d.%H%M%S')


define build_image
	$(eval image := $(1))
	$(eval target := $(2))
	$(eval image_name := ${DOCKER_REPOSITORY_PREFIX}-${image}-${target})
	$(eval latest_tags := \
		$(if push_latest_tags, -t ${image_name}:latest -t ${DOCKER_USER}/${image_name}:latest))
	@echo "\nBuilding Docker image '${image_name}'...\n" \
	&& cd ${image} \
	&& docker build ${BUILD_CACHE_OPT} \
		-f ${target}.Dockerfile \
		-t ${image_name} \
		-t ${image_name}:${BUILD_NUMBER} \
		-t ${DOCKER_USER}/${image_name} \
		-t ${DOCKER_USER}/${image_name}:${BUILD_NUMBER} \
		${latest_tags} \
		.
endef

define push_image
	$(eval image := $(1))
	$(eval target := $(2))
	$(eval image_name := ${DOCKER_REPOSITORY_PREFIX}-${image}-${target})
	@echo "\nPushing Docker image '${image_name}'...\n"\
	&& docker push ${DOCKER_USER}/${image_name} \
	&& docker push ${DOCKER_USER}/${image_name}:${BUILD_NUMBER} \
	&& @if [ ${push_latest_tags} == true ]; then docker push ${DOCKER_USER}/${image_name}:latest; fi
endef

# 1 --> LIB_PATH
# 2 --> REPOSITORY
# 3 --> BRANCH
# 4 --> REVISION
define clone_repository
	@if [ ! -d ${1} ]; then \
		git clone --single-branch -j8 \
				--branch ${3} ${2} ${1} \
		&& cd ${1} \
		&& if [ -n ${4} ]; then git reset --hard ${4} ; fi \
		&& git submodule update --init ; \
	else \
		echo "Using existing ${1} repository..." ;  \
	fi
endef


.DEFAULT_GOAL := help

help: ## Show help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

libs_folder:
	$(info Creating ${LOCAL_LIBS_PATH} folder...)
	@mkdir -p ${LOCAL_LIBS_PATH}

pylibs_folder:
	@mkdir -p ${LOCAL_PYLIBS_PATH}

clone_ecvl:	libs_folder
	$(call clone_repository,${ECVL_LIB_PATH},${ECVL_REPOSITORY},${ECVL_BRANCH},${ECVL_REVISION})

clone_pyecvl: pylibs_folder
	$(call clone_repository,${PYECVL_LIB_PATH},${PYECVL_REPOSITORY},${PYECVL_BRANCH},${PYECVL_REVISION})

clone_eddl: libs_folder	
	$(call clone_repository,${EDDL_LIB_PATH},${EDDL_REPOSITORY},${EDDL_BRANCH},${EDDL_REVISION})

clone_pyeddl: pylibs_folder
	$(call clone_repository,${PYEDDL_LIB_PATH},${PYEDDL_REPOSITORY},${PYEDDL_BRANCH},${PYEDDL_REVISION})

# Targets to build container images
build: build_libs_develop \ ## Build and tag all Docker images
	build_libs_runtime \
	build_pylibs_develop \
	build_pylibs_runtime

build_libs_develop: clone_ecvl clone_eddl ## Build and tag 'libs-develop' image
	$(call build_image,libs,develop)

build_libs_runtime: build_libs_develop ## Build and tag 'libs-runtime' image
	$(call build_image,libs,runtime)

build_pylibs_develop: clone_pyecvl clone_pyeddl ## Build and tag 'pylibs-develop' image
	$(call build_image,pylibs,develop)

build_pylibs_runtime: build_pylibs_develop ## Build and tag 'pylibs-runtime' image
	$(call build_image,pylibs,runtime)

# Docker publish
publish: \ ## Publish all build images to a Docker Registry (e.g., DockerHub)
	repo-login \
	publish_libs_develop publish_libs_runtime \
	publish_pylibs_develop publish_pylibs_runtime ## Publish the `{version}` ans `latest` tagged containers to ECR

publish_libs_develop: ## Publish 'libs-develop' images
	$(call push_image,libs,develop)

publish_libs_runtime: ## Publish 'libs-runtime' images
	$(call push_image,libs,runtime)

publish_pylibs_develop: ## Publish 'pylibs-develop' images
	$(call push_image,pylibs,develop)

publish_pylibs_runtime: ## Publish 'pylibs-runtime' images
	$(call push_image,pylibs,runtime)

# login to the Docker HUB repository
repo-login: ## Login to the Docker Registry
	@echo ${DOCKER_PASSWORD} | docker login -u ${DOCKER_USER} --password-stdin

version: ## Output the current BUILD_NUMBER
	@echo $(BUILD_NUMBER)

clean:
	@echo "Removing $(LOCAL_LIBS_PATH)/{eddl,ecvl}..."
	@rm -rf $(LOCAL_LIBS_PATH)/{eddl,ecvl}	
	@echo "Removing $(LOCAL_LIBS_PATH)/{eddl,ecvl}... DONE"
	@echo "Removing $(LOCAL_PYLIBS_PATH)/{eddl,ecvl}..."
	@rm -rf $(LOCAL_PYLIBS_PATH)/{pyeddl,pyecvl}
	@echo "Removing $(LOCAL_PYLIBS_PATH)/{eddl,ecvl}... DONE"

.PHONY: help clean \	
	repo-login publish \
	build build_libs_develop build_libs_runtime \
	build_pylibs_develop build_pylibs_runtime \
	clone_ecvl clone_eddl clone_pyecvl clone_pyeddl \
	publish_libs_develop publish_libs_runtime \
	publish_pylibs_develop publish_pylibs_runtime
