# version
VERSION := 0.1

# set bash as default interpreter
SHELL := /bin/bash

# date.time as build number
BUILD_NUMBER := $(or ${BUILD_NUMBER},$(shell date '+%Y%m%d.%H%M%S'))

# set docker user credentials
DOCKER_USER := $(or ${DOCKER_USER},${USER})
DOCKER_PASSWORD := ${DOCKER_PASSWORD}

# use DockerHub as default registry
DOCKER_REGISTRY := $(or ${DOCKER_REGISTRY},registry.hub.docker.com)

# set Docker repository
DOCKER_REPOSITORY_OWNER := $(or ${DOCKER_REPOSITORY_OWNER},${DOCKER_USER})
#DOCKER_IMAGE_PREFIX ?= deephealth-
runtime_suffix = 
develop_suffix = -toolkit

# latest tag settings
DOCKER_IMAGE_LATEST := $(or ${DOCKER_IMAGE_LATEST},false)

# extra tags
DOCKER_IMAGE_TAG_EXTRA := ${DOCKER_IMAGE_TAG_EXTRA}

# set default Docker image TAG
DOCKER_IMAGE_TAG := $(or ${DOCKER_IMAGE_TAG},${BUILD_NUMBER})

# current path
CURRENT_PATH := $(PWD)

# libraries path
LOCAL_LIBS_PATH = libs
LOCAL_PYLIBS_PATH = pylibs
ECVL_LIB_PATH = ${LOCAL_LIBS_PATH}/ecvl
EDDL_LIB_PATH = ${LOCAL_LIBS_PATH}/eddl
PYECVL_LIB_PATH = ${LOCAL_PYLIBS_PATH}/pyecvl
PYEDDL_LIB_PATH = ${LOCAL_PYLIBS_PATH}/pyeddl

# ECVL repository
ECVL_REPOSITORY := $(or ${ECVL_REPOSITORY},https://github.com/deephealthproject/ecvl.git)
ECVL_BRANCH := $(or ${ECVL_BRANCH},master)
ECVL_REVISION := ${ECVL_REVISION}

# PyECVL repository
PYECVL_REPOSITORY := $(or ${PYECVL_REPOSITORY},https://github.com/deephealthproject/pyecvl.git)
PYECVL_BRANCH := $(or ${PYECVL_BRANCH},master)
PYECVL_REVISION := ${PYECVL_REVISION}

# EDDL repository
EDDL_REPOSITORY := $(or ${EDDL_REPOSITORY},https://github.com/deephealthproject/eddl.git)
EDDL_BRANCH := $(or ${EDDL_BRANCH},master)
EDDL_REVISION := ${EDDL_REVISION}

# PyEDDL repository
PYEDDL_REPOSITORY := $(or ${PYEDDL_REPOSITORY},https://github.com/deephealthproject/pyeddl.git)
PYEDDL_BRANCH := $(or ${PYEDDL_BRANCH},master)
PYEDDL_REVISION := ${PYEDDL_REVISION} 

# config file
CONFIG_FILE ?= settings.sh
ifneq ($(wildcard $(CONFIG_FILE)),)
include $(CONFIG_FILE)
endif

# set no cache option
DISABLE_CACHE ?= 
BUILD_CACHE_OPT ?= 
ifneq ("$(DISABLE_CACHE)", "")
BUILD_CACHE_OPT = --no-cache
endif

# enable latest tags
push_latest_tags = false
ifeq ("${DOCKER_IMAGE_LATEST}", "true")
	push_latest_tags = true
endif

# auxiliary flag 
DOCKER_LOGIN_DONE = false

define build_image
	$(eval image := $(1))
	$(eval target := $(2))
	$(eval labels := $(3))
	$(eval base := $(if $(4), --build-arg BASE_IMAGE=$(4)))
	$(eval toolkit := $(if $(5), --build-arg TOOLKIT_IMAGE=$(5)))
	$(eval image_name := ${DOCKER_IMAGE_PREFIX}${image}${${target}_suffix})
	$(eval latest_tags := $(shell if [ "${push_latest_tags}" == "true" ]; then echo "-t ${image_name}:latest"; fi))
	@echo "Building Docker image '${image_name}'..."
	cd ${image} \
	&& docker build ${BUILD_CACHE_OPT} \
		-f ${target}.Dockerfile \
		   ${base} ${toolkit} \
		-t ${image_name}:${DOCKER_IMAGE_TAG} ${latest_tags} ${labels} .
endef

define push_image
	$(eval image := $(1))
	$(eval target := $(2))
	$(eval image_name := ${DOCKER_IMAGE_PREFIX}${image}${${target}_suffix})
	$(eval full_image_name := ${DOCKER_REGISTRY}/${DOCKER_REPOSITORY_OWNER}/${image_name})
	$(eval full_tag := ${full_image_name}:$(DOCKER_IMAGE_TAG))
	$(eval latest_tag := ${full_image_name}:latest)
	$(eval tags := ${DOCKER_IMAGE_TAG_EXTRA})
	@echo "Tagging images... "
	docker tag ${image_name}:$(DOCKER_IMAGE_TAG) ${full_tag}
	@if [ ${push_latest_tags} == true ]; then docker tag ${image_name}:$(DOCKER_IMAGE_TAG) ${latest_tag}; fi
	@echo "Pushing Docker image '${image_name}'..."	
	docker push ${full_tag}
	@if [ ${push_latest_tags} == true ]; then docker push ${latest_tag}; fi
	@for tag in $(tags); \
	do \
	img_tag=${full_image_name}:$$tag ; \
	docker tag ${full_tag} $$img_tag ; \
	docker push $$img_tag ; \
	done
endef

# 1 --> LIB_PATH
# 2 --> REPOSITORY
# 3 --> BRANCH
# 4 --> REVISION
# 5 --> RECURSIVE SUBMODULE CLONE (true|false)
define clone_repository
	if [ ! -d ${1} ]; then \
		git clone --branch "${3}" ${2} ${1} \
		&& cd "${1}" \
		&& if [ -n "${4}" ]; then git reset --hard "${4}" ; fi \
		&& if [ ${5} == true ]; then git submodule update --init --recursive ; fi \
	else \
		echo "Using existing ${1} repository..." ;  \
	fi
endef


define clean_build
	$(eval lib := $(1)) # libs or pylibs
	@echo "Removing $(lib)/{eddl,ecvl}..."
	@rm -rf $(lib)/{*eddl,*ecvl}
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
	@docker tag ${DOCKER_IMAGE_PREFIX}libs${develop_suffix}:${DOCKER_IMAGE_TAG} ecvl
	@cd ${PYECVL_LIB_PATH} && bash generate_bindings.sh

pyeddl_folder: pylibs_folder
	$(call clone_repository,${PYEDDL_LIB_PATH},${PYEDDL_REPOSITORY},${PYEDDL_BRANCH},${PYEDDL_REVISION},false)
	@echo "Copying revision '${EDDL_REVISION}' of EDDL library..."
	@rm -rf ${PYEDDL_LIB_PATH}/third_party/eddl
	@cp -a ${EDDL_LIB_PATH} ${PYEDDL_LIB_PATH}/third_party/eddl
	@docker tag ${DOCKER_IMAGE_PREFIX}libs${develop_suffix}:${DOCKER_IMAGE_TAG} ecvl
	@echo "Building Python ECVL Python bindings..."
	@cd ${PYEDDL_LIB_PATH} && bash generate_bindings.sh

apply_libs_patches:
	# $(call clone_repository,${PYEDDL_LIB_PATH},${PYEDDL_REPOSITORY},${PYEDDL_BRANCH},${PYEDDL_REVISION},false)
	# # TODO: remove this patch when not required
	# @echo "Applying patches to the EDDL repository..."
	# cd ${EDDL_LIB_PATH} && git apply ../../${PYEDDL_LIB_PATH}/eddl.diff || true
	# @echo "Copying revision '${EDDL_REVISION}' of EDDL library..."
	# @rm -rf ${PYEDDL_LIB_PATH}/third_party/eddl
	# @cp -a ${EDDL_LIB_PATH} ${PYEDDL_LIB_PATH}/third_party/eddl

# Targets to build container images
build: _build ## Build and tag all Docker images
_build: \
	build_libs \
	build_pylibs

build_libs: build_libs_toolkit ## Build and tag 'libs' image
	$(call build_image,libs,runtime,\
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=$(call get_revision,${EDDL_LIB_PATH},${EDDL_REVISION}) \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=$(call get_revision,${ECVL_LIB_PATH},${ECVL_REVISION}),libs-toolkit:$(DOCKER_IMAGE_TAG))

build_libs_toolkit: ecvl_folder eddl_folder ## Build and tag 'libs-toolkit' image
	$(call build_image,libs,develop,\
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=$(call get_revision,${EDDL_LIB_PATH},${EDDL_REVISION}) \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=$(call get_revision,${ECVL_LIB_PATH},${ECVL_REVISION}) \
		)

build_pylibs: build_pylibs_toolkit ## Build and tag 'pylibs' image
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
		--label PYEDDL_REVISION=$(call get_revision,${PYEDDL_LIB_PATH},${PYEDDL_REVISION}),libs:$(DOCKER_IMAGE_TAG),pylibs-toolkit:$(DOCKER_IMAGE_TAG))

build_pylibs_toolkit: pyecvl_folder pyeddl_folder ## Build and tag 'pylibs-toolkit' image
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
		--label PYEDDL_REVISION=$(call get_revision,${PYEDDL_LIB_PATH},${PYEDDL_REVISION}),libs-toolkit:$(DOCKER_IMAGE_TAG))
		
# Docker push
push: _push ## Push all built images
_push: \
	push_libs_toolkit push_libs \
	push_pylibs_toolkit push_pylibs 

push_libs: repo-login ## Push 'libs' images
	$(call push_image,libs,runtime)

push_libs_toolkit: repo-login ## Push 'libs-toolkit' images
	$(call push_image,libs,develop)

push_pylibs: repo-login ## Push 'pylibs' images
	$(call push_image,pylibs,runtime)

push_pylibs_toolkit: repo-login ## Push 'pylibs-toolkit' images
	$(call push_image,pylibs,develop)

# Docker publish
publish: build push ## Publish all built images to a Docker Registry (e.g., DockerHub)

publish_libs: build_libs push_libs ## Publish 'libs' images

publish_libs_toolkit: build_libs_toolkit push_libs_toolkit ## Publish 'libs-toolkit' images

publish_pylibs: build_pylibs push_pylibs ## Publish 'pylibs' images

publish_pylibs_toolkit: build_pylibs_toolkit push_pylibs_toolkit ## Publish 'pylibs-toolkit' images

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


.PHONY: help clean clean_libs clean_pylibs apply_libs_patches \
	build _build build_libs_toolkit build_libs \
	build_pylibs_toolkit build_pylibs \
	ecvl_folder eddl_folder pyecvl_folder pyeddl_folder \
	repo-login \
	push \
	_push push_libs_toolkit push_libs \
	push_pylibs_toolkit push_pylibs \
	publish \
	publish_libs_toolkit publish_libs \
	publish_pylibs_toolkit publish_pylibs