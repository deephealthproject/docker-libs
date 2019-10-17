# version
VERSION ?= 1.0

# set docker user credentials
DOCKER_USER ?= ${USER}
DOCKER_PASSWORD ?= ""

# use DockerHub as default registry
DOCKER_REGISTRY ?= registry.hub.docker.com

# set Docker repository
DOCKER_REPOSITORY_OWNER ?= ${DOCKER_USER}
#DOCKER_IMAGE_PREFIX ?= deephealth-

# latest tag settings
LATEST_BRANCH ?= master

# config file
BUILD_CONF ?= settings.sh
ifneq ("$(wildcard $(BUILD_CONF))","")
include $(BUILD_CONF)
export $(shell sed 's/=.*//' $(BUILD_CONF))
endif

# current path
CURRENT_PATH := $(PWD)

# libraries path
LOCAL_LIBS_PATH = libs
LOCAL_PYLIBS_PATH = pylibs
ECVL_LIB_PATH = ${LOCAL_LIBS_PATH}/ecvl
EDDL_LIB_PATH = ${LOCAL_LIBS_PATH}/eddl
PYECVL_LIB_PATH = ${LOCAL_PYLIBS_PATH}/pyecvl
PYEDDL_LIB_PATH = ${LOCAL_PYLIBS_PATH}/pyeddl

# software repositories
ECVL_BRANCH ?= $(shell cd ${ECVL_LIB_PATH} && git rev-parse --abbrev-ref HEAD)
EDDL_BRANCH ?= $(shell cd ${EDDL_LIB_PATH} && git rev-parse --abbrev-ref HEAD)
PYECVL_BRANCH ?= $(shell cd ${PYECVL_LIB_PATH} && git rev-parse --abbrev-ref HEAD)
PYEDDL_BRANCH ?= $(shell cd ${PYEDDL_LIB_PATH} && git rev-parse --abbrev-ref HEAD)
ECVL_REVISION ?= 
EDDL_REVISION ?= 
PYECVL_REVISION ?= 
PYEDDL_REVISION ?= 
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

# auxiliary flag 
DOCKER_LOGIN_DONE = false

# date.time as build number
BUILD_NUMBER := $(shell date '+%Y%m%d.%H%M%S')


define build_image
	$(eval image := $(1))
	$(eval target := $(2))
	$(eval labels := $(3))
	$(eval image_name := ${DOCKER_IMAGE_PREFIX}${image}-${target})
	$(eval latest_tags := \
		$(if push_latest_tags, -t ${image_name}:latest -t ${DOCKER_USER}/${image_name}:latest))	
	@echo "\nBuilding Docker image '${image_name}'...\n" \	
	cd ${image} \
	&& docker build ${BUILD_CACHE_OPT} \
		-f ${target}.Dockerfile \
		-t ${image_name} \
		-t ${image_name}:${BUILD_NUMBER} \
		-t ${DOCKER_USER}/${image_name} \
		-t ${DOCKER_USER}/${image_name}:${BUILD_NUMBER} \
		${latest_tags} \
		${labels} \
		.
endef

define push_image
	$(eval image := $(1))
	$(eval target := $(2))
	$(eval image_name := ${DOCKER_IMAGE_PREFIX}${image}-${target})
	@echo "\nPushing Docker image '${image_name}'...\n"	
	docker push ${DOCKER_USER}/${image_name}
	docker push ${DOCKER_USER}/${image_name}:${BUILD_NUMBER}
	@if [ ${push_latest_tags} == true ]; then docker push ${DOCKER_USER}/${image_name}:latest; fi
endef

# 1 --> LIB_PATH
# 2 --> REPOSITORY
# 3 --> BRANCH
# 4 --> REVISION
# 5 --> RECURSIVE SUBMODULE CLONE (true|false)
define clone_repository
	@if [ ! -d ${1} ]; then \
		git clone --single-branch -j8 \
				--branch ${3} ${2} ${1} \
		&& cd ${1} \
		&& if [ -n ${4} ]; then git reset --hard ${4} ; fi \
		&& if [ ${5} == true ]; then git submodule update --init --recursive ; fi \
	else \
		echo "Using existing ${1} repository..." ;  \
	fi
endef


define clean_build
	$(eval lib := $(1)) # libs or pylibs
	@echo "Removing $(lib)/{eddl,ecvl}..."
	@rm -rf $(LOCAL_PYLIBS_PATH)/{*eddl,*ecvl}
	@echo "Removing sources... DONE"	
	@echo "Stopping docker containers... "
	@docker ps -a | grep -E "(${DOCKER_IMAGE_PREFIX})?$(lib)-(runtime|develop)" | awk '{print $$1}' | xargs docker rm -f 
	@echo "Stopping docker containers... DONE"
	@echo "Removing docker images... "
	@docker images | grep -E "(${DOCKER_IMAGE_PREFIX})?$(lib)-(runtime|develop)" | awk '{print $$3}' | xargs docker rmi -f
	@echo "Removing docker images... DONE"
endef


# 1: library path
# 2: actual revision
define get_revision	
$(shell if [[ -z "${2}" ]]; then cd ${1} && git rev-parse HEAD; else echo "${2}" ; fi)
endef

.DEFAULT_GOAL := help

help: ## Show help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

libs_folder:
	$(info Creating ${LOCAL_LIBS_PATH} folder...)
	@mkdir -p ${LOCAL_LIBS_PATH}

ecvl_folder: libs_folder
	$(call clone_repository,${ECVL_LIB_PATH},${ECVL_REPOSITORY},${ECVL_BRANCH},${ECVL_REVISION},true)

eddl_folder: libs_folder	
	$(call clone_repository,${EDDL_LIB_PATH},${EDDL_REPOSITORY},${EDDL_BRANCH},${EDDL_REVISION},true)

pylibs_folder:
	@mkdir -p ${LOCAL_PYLIBS_PATH}

pyecvl_folder: pylibs_folder
	$(call clone_repository,${PYECVL_LIB_PATH},${PYECVL_REPOSITORY},${PYECVL_BRANCH},${PYECVL_REVISION},false)
	@echo "Copying revision '${ECVL_REVISION}' of ECVL library..."
	@rm -rf ${PYECVL_LIB_PATH}/third_party/ecvl
	@cp -a ${CURRENT_PATH}/${ECVL_LIB_PATH} ${CURRENT_PATH}/${PYECVL_LIB_PATH}/third_party/ecvl 
	@echo "Building Python ECVL Python bindings..."
	@docker tag ${DOCKER_IMAGE_PREFIX}libs-develop ecvl
	@cd ${PYECVL_LIB_PATH} && bash generate_bindings.sh

pyeddl_folder: pylibs_folder
	$(call clone_repository,${PYEDDL_LIB_PATH},${PYEDDL_REPOSITORY},${PYEDDL_BRANCH},${PYEDDL_REVISION},false)
	@echo "Copying revision '${EDDL_REVISION}' of EDDL library..."
	@rm -rf ${PYEDDL_LIB_PATH}/third_party/eddl
	@cp -a ${EDDL_LIB_PATH} ${PYEDDL_LIB_PATH}/third_party/eddl
	@echo "Building Python ECVL Python bindings..."
	@cd ${PYEDDL_LIB_PATH} && bash generate_bindings.sh

# Targets to build container images
build: _build ## Build and tag all Docker images
_build: \
	build_libs_develop build_libs_runtime \
	build_pylibs_develop build_pylibs_runtime

build_libs_develop: ecvl_folder eddl_folder ## Build and tag 'libs-develop' image
	$(call build_image,libs,develop,\
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=$(call get_revision,${EDDL_LIB_PATH},${EDDL_REVISION}) \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=$(call get_revision,${ECVL_LIB_PATH},${ECVL_REVISION}) \
		)

build_libs_runtime: build_libs_develop ## Build and tag 'libs-runtime' image
	$(call build_image,libs,runtime,\
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=$(call get_revision,${EDDL_LIB_PATH},${EDDL_REVISION}) \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=$(call get_revision,${ECVL_LIB_PATH},${ECVL_REVISION}) \
		)

build_pylibs_develop: pyecvl_folder pyeddl_folder ## Build and tag 'pylibs-develop' image
	$(call build_image,pylibs,develop,\
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=$(call get_revision,${EDDL_LIB_PATH},${EDDL_REVISION}) \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=$(call get_revision,${ECVL_LIB_PATH},${ECVL_REVISION}) \
		--label PYECVL_REPOSITORY=${PYECVL_REPOSITORY} \
		--label PYECVL_BRANCH=${PYECVL_BRANCH} \
		--label PYECVL_REVISION=$(call get_revision,${PYECVL_LIB_PATH},${PYECVL_REVISION}) \
		--label PYEDDL_REPOSITORY=${PYEDDL_REPOSITORY} \
		--label PYEDDL_BRANCH=${PYEDDL_BRANCH} \
		--label PYEDDL_REVISION=$(call get_revision,${PYEDDL_LIB_PATH},${PYEDDL_REVISION}) \
		)

build_pylibs_runtime: build_pylibs_develop ## Build and tag 'pylibs-runtime' image
	$(call build_image,pylibs,runtime,\
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=$(call get_revision,${EDDL_LIB_PATH},${EDDL_REVISION}) \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=$(call get_revision,${ECVL_LIB_PATH},${ECVL_REVISION}) \
		--label PYECVL_REPOSITORY=${PYECVL_REPOSITORY} \
		--label PYECVL_BRANCH=${PYECVL_BRANCH} \
		--label PYECVL_REVISION=$(call get_revision,${PYECVL_LIB_PATH},${PYECVL_REVISION}) \
		--label PYEDDL_REPOSITORY=${PYEDDL_REPOSITORY} \
		--label PYEDDL_BRANCH=${PYEDDL_BRANCH} \
		--label PYEDDL_REVISION=$(call get_revision,${PYEDDL_LIB_PATH},${PYEDDL_REVISION}) \
		)


# Docker push
push: _push ## Push all built images
_push: \
	push_libs_develop push_libs_runtime \
	push_pylibs_develop push_pylibs_runtime 

push_libs_develop: repo-login ## Push 'libs-develop' images
	$(call push_image,libs,develop)

push_libs_runtime: repo-login ## Push 'libs-runtime' images
	$(call push_image,libs,runtime)

push_pylibs_develop: repo-login ## Push 'pylibs-develop' images
	$(call push_image,pylibs,develop)

push_pylibs_runtime: repo-login ## Push 'pylibs-runtime' images
	$(call push_image,pylibs,runtime)

# Docker publish
publish: build push ## Publish all built images to a Docker Registry (e.g., DockerHub)

publish_libs_develop: build_libs_develop push_libs_develop ## Publish 'libs-develop' images

publish_libs_runtime: build_libs_runtime push_libs_runtime ## Publish 'libs-runtime' images

publish_pylibs_develop: build_pylibs_develop push_pylibs_develop ## Publish 'pylibs-develop' images

publish_pylibs_runtime: build_pylibs_runtime push_pylibs_runtime ## Publish 'pylibs-runtime' images

# login to the Docker HUB repository
repo-login: ## Login to the Docker Registry
	@if [[ ${DOCKER_LOGIN_DONE} == false ]]; then \
		echo "Logging into Docker registry ${DOCKER_REGISTRY}..." ; \
		echo ${DOCKER_PASSWORD} | docker login ${DOCKER_REGISTRY} -u ${DOCKER_USER} --password-stdin ; \
		DOCKER_LOGIN_DONE=true ;\
	fi

version: ## Output the current version of this Makefile
	@echo $(VERSION)

clean: clean_libs clean_pylibs	

clean_libs: 
	$(call clean_build,libs)

clean_pylibs: 
	$(call clean_build,pylibs)


.PHONY: help clean clean_libs clean pylibs \
	build _build build_libs_develop build_libs_runtime \
	build_pylibs_develop build_pylibs_runtime \
	ecvl_folder eddl_folder pyecvl_folder pyeddl_folder \
	repo-login \
	push \
	_push push_libs_develop push_libs_runtime \
	push_pylibs_develop push_pylibs_runtime \
	publish \
	publish_libs_develop publish_libs_runtime \
	publish_pylibs_develop publish_pylibs_runtime