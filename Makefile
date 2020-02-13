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
DOCKER_REGISTRY := $(or ${DOCKER_REGISTRY},)

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

# set default Base images
DOCKER_BASE_IMAGE_SKIP_PULL := $(or ${DOCKER_BASE_IMAGE_SKIP_PULL},true)
DOCKER_NVIDIA_DEVELOP_IMAGE := $(or ${DOCKER_NVIDIA_DEVELOP_IMAGE},nvidia/cuda:10.1-devel)
DOCKER_NVIDIA_RUNTIME_IMAGE := $(or ${DOCKER_NVIDIA_RUNTIME_IMAGE},nvidia/cuda:10.1-runtime)

DOCKER_BASE_IMAGE_VERSION_TAG := $(or ${DOCKER_BASE_IMAGE_VERSION_TAG},${DOCKER_IMAGE_TAG})
EDDL_IMAGE_VERSION_TAG := $(or ${EDDL_IMAGE_VERSION_TAG},${EDDL_REVISION})
ECVL_IMAGE_VERSION_TAG := $(or ${ECVL_IMAGE_VERSION_TAG},${ECVL_REVISION})
PYEDDL_IMAGE_VERSION_TAG := $(or ${PYEDDL_IMAGE_VERSION_TAG},${PYEDDL_REVISION})
PYECVL_IMAGE_VERSION_TAG := $(or ${PYECVL_IMAGE_VERSION_TAG},${PYECVL_REVISION})

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
DOCKER_LOGIN_DONE := $(or ${DOCKER_LOGIN_DONE},false)

#$(if docker images -q ${image_name}:${tag} > /dev/null || docker images -q ${full_tag} > /dev/null, 
define build_image
	$(eval image := $(1))
	$(eval target := $(2))
	$(eval tag := $(3))
	$(eval labels := $(4))
	$(eval base := $(if $(5), --build-arg BASE_IMAGE=$(5)))
	$(eval toolkit := $(if $(6), --build-arg TOOLKIT_IMAGE=$(6)))
	$(eval extra_tags := $(if $(7), -t ${image_name}:${7}))
	$(eval image_name := ${DOCKER_IMAGE_PREFIX}${target}${${target}_suffix})
	$(eval full_image_name := $(shell prefix=""; if [ -n "${DOCKER_REGISTRY}" ]; then prefix="${DOCKER_REGISTRY}/"; fi; echo "${prefix}${DOCKER_REPOSITORY_OWNER}/${image_name}"))
	$(eval latest_tags := $(shell if [ "${push_latest_tags}" == "true" ]; then echo "-t ${image_name}:latest"; fi))
	$(eval tagged_image := ${image_name}:${tag})
	@echo "Building Docker image '${image_name}'..."
	$(eval images := $(shell docker images -q ${tagged_image}))
	$(eval exists := $(shell curl --silent -f -lSL https://index.docker.io/v1/repositories/${full_image_name}/tags/${tag}))
	$(if ${images},\
		echo "Docker image '${tagged_image}' exists (id: ${images})", \
		$(if ${exists}, \
			echo "Pulling image '${full_image_name}:${tag}'..."; 
			docker pull ${full_image_name}:${tag} && docker tag ${full_image_name}:${tag} ${tagged_image}, \
			echo "Building Docker image '${image_name}'..." ; \
			cd ${image} \
			&& docker build ${BUILD_CACHE_OPT} \
				-f ${target}.Dockerfile \
				${base} ${toolkit} \
				-t ${image_name}:${tag} ${extra_tags} ${latest_tags} ${labels} . \
		)
	)
endef

define push_image
	$(eval image := $(1))
	$(eval tag := $(or $(2),${DOCKER_IMAGE_TAG}))
	$(eval image_name := ${DOCKER_IMAGE_PREFIX}${image})
	$(eval full_image_name := $(shell prefix=""; if [ -n "${DOCKER_REGISTRY}" ]; then prefix="${DOCKER_REGISTRY}/"; fi; echo "${prefix}${DOCKER_REPOSITORY_OWNER}/${image_name}"))
	$(eval full_tag := ${full_image_name}:$(tag))
	$(eval latest_tag := ${full_image_name}:latest)
	$(eval tags := ${DOCKER_IMAGE_TAG_EXTRA})
	@echo "Tagging images... "
	docker tag ${image_name}:$(tag) ${full_tag}
	@if [ ${push_latest_tags} == true ]; then docker tag ${image_name}:$(tag) ${latest_tag}; fi
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
		&& if [ -n "${4}" ]; then git reset --hard ${4} -- ; fi \
		&& if [ ${5} == true ]; then git submodule update --init --recursive ; fi \
		&& cd - ; \
	else \
		echo "Using existing ${1} repository..." ;  \
	fi
endef


define clean_sources
	$(eval path := $(1))
	@printf "Removing sources '$(path)'... "
	@rm -rf $(path)
	@printf "DONE\n"	
endef


define clean_image
	$(eval image := $(1))
	@printf "Stopping docker containers instances of image '$(image)'... "
	@docker ps -a | grep -E "^$(image)\s" | awk '{print $$1}' | xargs docker rm -f  || true
	@printf "DONE\n"
	@printf "Removing docker image '$(image)'... "
	@docker images | grep -E "^$(image)\s" | awk '{print $$1 ":" $$2}' | xargs docker rmi -f  || true	
	@printf "DONE\n"
	@printf "Removing unused docker image... "
	@docker image prune -f
	@printf "DONE\n"
endef


# 1: library path
# 2: actual revision
define get_revision	
	$(eval tag := $(shell cd ${1} && git tag -l --points-at HEAD)) \
	$(eval head := $(shell cd ${1} && git rev-parse --short HEAD | sed -E 's/-//; s/ .*//')) \
	$(strip $(shell if [[ -n "${2}" ]]; then echo ${2}; elif [[ -n "${tag}" ]]; then echo ${tag}; else echo ${head}; fi))
endef

.DEFAULT_GOAL := help

help: ## Show help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

libs_folder:
	$(if $(wildcard ${LOCAL_LIBS_PATH}),, \
		$(info Creating ${LOCAL_LIBS_PATH} folder...) ; \
		@mkdir -p ${LOCAL_LIBS_PATH} ; \
	)

_eddl_folder: libs_folder
	$(if $(wildcard ${EDDL_LIB_PATH}),$(info Using existing '${EDDL_LIB_PATH}' repository), \
		$(call clone_repository,${EDDL_LIB_PATH},${EDDL_REPOSITORY},${EDDL_BRANCH},${EDDL_REVISION},true) ; \
	)

eddl_folder: _eddl_folder
	$(eval EDDL_REVISION := $(call get_revision,libs/eddl,${EDDL_REVISION}))


define clone_ecvl
	$(if $(wildcard ${ECVL_LIB_PATH}),$(info Using existing '${ECVL_LIB_PATH}' repository), \
		$(call clone_repository,${ECVL_LIB_PATH},${ECVL_REPOSITORY},${ECVL_BRANCH},${ECVL_REVISION},true) ; \
	)
endef

_ecvl_folder: libs_folder
	$(call clone_ecvl)

ecvl_folder: _ecvl_folder
	$(eval ECVL_REVISION := $(call get_revision,libs/ecvl,${ECVL_REVISION}))

pylibs_folder:
	@mkdir -p ${LOCAL_PYLIBS_PATH}

define pyeddl_shallow_clone
	$(if $(wildcard ${PYEDDL_LIB_PATH}),$(info Using existing '${PYEDDL_LIB_PATH}' repository), \
		$(call clone_repository,${PYEDDL_LIB_PATH},${PYEDDL_REPOSITORY},${PYEDDL_BRANCH},${PYEDDL_REVISION},false) ; \
	)
endef

define pyeddl_clone_dependencies
	$(eval EDDL_REVISION = $(shell if [[ ! -n "${EDDL_REVISION}" ]]; then cd ${CURRENT_PATH}/${PYEDDL_LIB_PATH} && git submodule status -- third_party/eddl | sed -E 's/-//; s/ .*//' | cut -c1-7; else echo ${EDDL_REVISION}; fi))
	@echo "EDDL_REVISION: ${EDDL_REVISION}"
	@if [[ -d ${EDDL_LIB_PATH} ]]; then \
		echo "Using existing '${EDDL_LIB_PATH}' repository" ; \
	else \
		$(call clone_repository,${EDDL_LIB_PATH},${EDDL_REPOSITORY},${EDDL_BRANCH},${EDDL_REVISION},true) ; \
		printf "Copying revision '${EDDL_REVISION}' of EDDL library... " ; \
		rm -rf ${PYEDDL_LIB_PATH}/third_party/eddl && cp -a ${EDDL_LIB_PATH} ${PYEDDL_LIB_PATH}/third_party/eddl ; \
		printf "DONE\n" ; \
	fi
endef

_pyeddl_shallow_clone: pylibs_folder
	@$(call pyeddl_shallow_clone)

pyeddl_folder: _pyeddl_shallow_clone
	$(call pyeddl_clone_dependencies)
	$(eval PYEDDL_REVISION := $(call get_revision,pylibs/pyeddl,${PYEDDL_REVISION}))

define pyecvl_shallow_clone
	@$(if $(wildcard ${PYECVL_LIB_PATH}),$(info Using existing '${PYECVL_LIB_PATH}' repository), \
		$(call clone_repository,${PYECVL_LIB_PATH},${PYECVL_REPOSITORY},${PYECVL_BRANCH},${PYECVL_REVISION},false) ; \
	)
endef

define pyecvl_resolve_dependencies
	$(eval PYEDDL_REVISION = $(shell if [[ ! -n "${PYEDDL_REVISION}" ]]; then cd ${CURRENT_PATH}/${PYECVL_LIB_PATH} && git submodule status -- third_party/pyeddl | sed -E 's/-//; s/ .*//' | cut -c1-7; else echo ${PYEDDL_REVISION}; fi))
	$(eval ECVL_REVISION = $(shell if [[ ! -n "${ECVL_REVISION}" ]]; then cd ${CURRENT_PATH}/${PYECVL_LIB_PATH} && git submodule status -- third_party/ecvl | sed -E 's/-//; s/ .*//' | cut -c1-7; else echo ${ECVL_REVISION}; fi))
	@if [[ -d ${PYEDDL_LIB_PATH} ]]; then \
		echo "Using existing '${PYEDDL_LIB_PATH}' repository" ; \
	else \
		$(call pyeddl_shallow_clone) \
		printf "Copying revision '${PYEDDL_REVISION}' of PYEDDL library... " ; \
		rm -rf ${PYECVL_LIB_PATH}/third_party/pyeddl && cp -a ${PYEDDL_LIB_PATH} ${PYECVL_LIB_PATH}/third_party/pyeddl ; \
		printf "DONE\n" ; \
	fi
	@if [[ -d ${ECVL_LIB_PATH} ]]; then \
		echo "Using existing '${ECVL_LIB_PATH}' repository" ; \
	else \
		echo "Using ECVL revision '${ECVL_REVISION}'" ; \
		$(call clone_ecvl) \
		printf "Copying revision '${ECVL_REVISION}' of ECVL library... " ; \
		rm -rf ${PYECVL_LIB_PATH}/third_party/ecvl && cp -a ${ECVL_LIB_PATH} ${PYECVL_LIB_PATH}/third_party/ecvl ; \
		printf "DONE\n" ; \
	fi
endef

_pyecvl_shallow_clone: pylibs_folder
	$(call pyecvl_shallow_clone)

_pyecvl_first_level_dependencies: _pyecvl_shallow_clone
	$(call pyecvl_resolve_dependencies)

_pyecvl_second_level_dependencies: _pyecvl_first_level_dependencies
	$(call pyeddl_clone_dependencies)

pyecvl_folder: _pyecvl_second_level_dependencies
	$(eval PYECVL_REVISION := $(call get_revision,pylibs/pyecvl,${PYECVL_REVISION}))


# TODO: remove this patch when not required
apply_pyeddl_patches:
	@echo "Applying patches to the EDDL repository..."
	$(call clone_repository,${PYEDDL_LIB_PATH},${PYEDDL_REPOSITORY},${PYEDDL_BRANCH},${PYEDDL_REVISION},false)
	cd ${EDDL_LIB_PATH} && git apply ../../${PYEDDL_LIB_PATH}/eddl_0.3.patch || true

# # TODO: remove this patch when not required
apply_pyecvl_patches:


#####################################################################################################################################
############# Build Docker images #############
#####################################################################################################################################
# Targets to build container images
build: _build ## Build libs+pylibs Docker images
_build: \
	build_libs \
	build_libs_toolkit \
	build_pylibs \
	build_pylibs_toolkit


############# libs-toolkit #############

_build_libs_base_toolkit:
	$(call build_image,libs,libs-base-toolkit,${DOCKER_BASE_IMAGE_VERSION_TAG},,$(DOCKER_NVIDIA_DEVELOP_IMAGE))

build_eddl_toolkit: eddl_folder _build_libs_base_toolkit apply_pyeddl_patches ## Build 'eddl-toolkit' image
	$(eval EDDL_IMAGE_VERSION_TAG := $(or ${EDDL_IMAGE_VERSION_TAG},${EDDL_REVISION}))
	$(call build_image,libs,eddl-toolkit,${EDDL_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=${DOCKER_IMAGE_TAG} \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION},libs-base-toolkit:$(DOCKER_BASE_IMAGE_VERSION_TAG))

build_ecvl_toolkit: ecvl_folder build_eddl_toolkit ## Build 'ecvl-toolkit' image
	$(eval ECVL_IMAGE_VERSION_TAG := $(or ${ECVL_IMAGE_VERSION_TAG},${ECVL_REVISION}))
	$(call build_image,libs,ecvl-toolkit,${ECVL_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=${DOCKER_IMAGE_TAG} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION},eddl-toolkit:$(EDDL_IMAGE_VERSION_TAG))

build_libs_toolkit: build_ecvl_toolkit ## Build 'libs-toolkit' image
	$(call build_image,libs,libs-toolkit,${DOCKER_IMAGE_TAG},\
		--label CONTAINER_VERSION=${DOCKER_IMAGE_TAG} \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION},ecvl-toolkit:$(ECVL_IMAGE_VERSION_TAG))



############# libs #############

_build_libs_base: 
	$(call build_image,libs,libs-base,${DOCKER_BASE_IMAGE_VERSION_TAG},,$(DOCKER_NVIDIA_RUNTIME_IMAGE))

build_eddl: _build_libs_base build_eddl_toolkit ## Build 'eddl' image
	$(eval EDDL_IMAGE_VERSION_TAG := $(or ${EDDL_IMAGE_VERSION_TAG},${EDDL_REVISION}))
	$(call build_image,libs,eddl,${EDDL_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=${DOCKER_IMAGE_TAG} \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION},libs-base:$(DOCKER_BASE_IMAGE_VERSION_TAG),eddl-toolkit:$(EDDL_IMAGE_VERSION_TAG))

build_ecvl: _build_libs_base build_ecvl_toolkit## Build 'ecvl' image
	$(eval ECVL_IMAGE_VERSION_TAG := $(or ${ECVL_IMAGE_VERSION_TAG},${ECVL_REVISION}))
	$(call build_image,libs,ecvl,${ECVL_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=${DOCKER_IMAGE_TAG} \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION},eddl:$(EDDL_IMAGE_VERSION_TAG),ecvl-toolkit:$(ECVL_IMAGE_VERSION_TAG))

build_libs: build_ecvl ## Build 'libs' image
	$(call build_image,libs,libs,${DOCKER_IMAGE_TAG},\
		--label CONTAINER_VERSION=${DOCKER_IMAGE_TAG} \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION},ecvl:$(ECVL_IMAGE_VERSION_TAG))



############# pylibs-toolkit #############

_build_pylibs_base_toolkit: build_ecvl_toolkit	
	$(call build_image,pylibs,pylibs-base-toolkit,${ECVL_IMAGE_VERSION_TAG},,ecvl-toolkit:$(ECVL_IMAGE_VERSION_TAG))

build_pyeddl_toolkit: pyeddl_folder _build_pylibs_base_toolkit apply_pyeddl_patches ## Build 'pyeddl-toolkit' image
	$(eval PYEDDL_IMAGE_VERSION_TAG := $(or ${PYEDDL_IMAGE_VERSION_TAG},${PYEDDL_REVISION}))
	$(call build_image,pylibs,pyeddl-toolkit,${PYEDDL_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=${DOCKER_IMAGE_TAG} \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION} \
		--label PYEDDL_REPOSITORY=${PYEDDL_REPOSITORY} \
		--label PYEDDL_BRANCH=${PYEDDL_BRANCH} \
		--label PYEDDL_REVISION=${PYEDDL_REVISION},pylibs-base-toolkit:$(ECVL_IMAGE_VERSION_TAG))

build_pyecvl_toolkit: pyecvl_folder build_pyeddl_toolkit ## Build 'pyecvl-toolkit' image
	$(eval PYECVL_IMAGE_VERSION_TAG := $(or ${PYECVL_IMAGE_VERSION_TAG},${PYECVL_REVISION}))
	$(call build_image,pylibs,pyecvl-toolkit,${PYECVL_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=${DOCKER_IMAGE_TAG} \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION} \
		--label PYECVL_REPOSITORY=${PYECVL_REPOSITORY} \
		--label PYECVL_BRANCH=${PYECVL_BRANCH} \
		--label PYECVL_REVISION=${PYECVL_REVISION} \
		--label PYEDDL_REPOSITORY=${PYEDDL_REPOSITORY} \
		--label PYEDDL_BRANCH=${PYEDDL_BRANCH} \
		--label PYEDDL_REVISION=${PYEDDL_REVISION},pyeddl-toolkit:$(PYEDDL_IMAGE_VERSION_TAG))

build_pylibs_toolkit: build_pyecvl_toolkit ## Build 'pylibs-toolkit' image
	$(call build_image,pylibs,pylibs-toolkit,${DOCKER_IMAGE_TAG},\
		--label CONTAINER_VERSION=${DOCKER_IMAGE_TAG} \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION} \
		--label PYECVL_REPOSITORY=${PYECVL_REPOSITORY} \
		--label PYECVL_BRANCH=${PYECVL_BRANCH} \
		--label PYECVL_REVISION=${PYECVL_REVISION} \
		--label PYEDDL_REPOSITORY=${PYEDDL_REPOSITORY} \
		--label PYEDDL_BRANCH=${PYEDDL_BRANCH} \
		--label PYEDDL_REVISION=${PYEDDL_REVISION},pyecvl-toolkit:$(PYECVL_IMAGE_VERSION_TAG))



############# pylibs #############

_build_pylibs_base: build_ecvl
	$(call build_image,pylibs,pylibs-base,${DOCKER_BASE_IMAGE_VERSION_TAG},,ecvl:$(ECVL_IMAGE_VERSION_TAG))

build_pyeddl: _build_pylibs_base build_pyeddl_toolkit ## Build 'pyeddl' image
	$(eval PYEDDL_IMAGE_VERSION_TAG := $(or ${PYEDDL_IMAGE_VERSION_TAG},${PYEDDL_REVISION}))
	$(call build_image,pylibs,pyeddl,${PYEDDL_IMAGE_VERSION_TAG},\
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION} \
		--label PYEDDL_REPOSITORY=${PYEDDL_REPOSITORY} \
		--label PYEDDL_BRANCH=${PYEDDL_BRANCH} \
		--label PYEDDL_REVISION=${PYEDDL_REVISION},pylibs-base:$(DOCKER_BASE_IMAGE_VERSION_TAG),pyeddl-toolkit:$(PYEDDL_IMAGE_VERSION_TAG))

build_pyecvl: build_pyeddl build_pyecvl_toolkit ## Build 'pyecvl' image
	$(eval PYECVL_IMAGE_VERSION_TAG := $(or ${PYECVL_IMAGE_VERSION_TAG},${PYECVL_REVISION}))
	$(call build_image,pylibs,pyecvl,${PYECVL_IMAGE_VERSION_TAG},\
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION} \
		--label PYECVL_REPOSITORY=${PYECVL_REPOSITORY} \
		--label PYECVL_BRANCH=${PYECVL_BRANCH} \
		--label PYECVL_REVISION=${PYECVL_REVISION} \
		--label PYEDDL_REPOSITORY=${PYEDDL_REPOSITORY} \
		--label PYEDDL_BRANCH=${PYEDDL_BRANCH} \
		--label PYEDDL_REVISION=${PYEDDL_REVISION},pyeddl:$(PYEDDL_IMAGE_VERSION_TAG),pyecvl-toolkit:$(PYECVL_IMAGE_VERSION_TAG))

build_pylibs: build_pyecvl ## Build 'pylibs' image
	$(call build_image,pylibs,pylibs,${DOCKER_IMAGE_TAG},\
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION} \
		--label PYECVL_REPOSITORY=${PYECVL_REPOSITORY} \
		--label PYECVL_BRANCH=${PYECVL_BRANCH} \
		--label PYECVL_REVISION=${PYECVL_REVISION} \
		--label PYEDDL_REPOSITORY=${PYEDDL_REPOSITORY} \
		--label PYEDDL_BRANCH=${PYEDDL_BRANCH} \
		--label PYEDDL_REVISION=${PYEDDL_REVISION},pyecvl:$(PYECVL_IMAGE_VERSION_TAG))

############################################################################################################################
### Push Docker images
############################################################################################################################
push: _push ## Push all built images
_push: \
	push_libs_toolkit push_libs \
	push_pylibs_toolkit push_pylibs 

push_libs: repo-login ## Push 'libs' images
	$(call push_image,libs)

push_eddl: repo-login eddl_folder ## Push 'eddl' images
	$(eval EDDL_IMAGE_VERSION_TAG := $(or ${EDDL_IMAGE_VERSION_TAG},${EDDL_REVISION}))
	$(call push_image,eddl,${EDDL_IMAGE_VERSION_TAG})

push_ecvl: repo-login ecvl_folder ## Push 'ecvl' images
	$(eval ECVL_IMAGE_VERSION_TAG := $(or ${ECVL_IMAGE_VERSION_TAG},${ECVL_REVISION}))
	$(call push_image,ecvl,${ECVL_IMAGE_VERSION_TAG})

push_libs_toolkit: repo-login ## Push 'libs-toolkit' images
	$(call push_image,libs-toolkit)

push_eddl_toolkit: repo-login eddl_folder ## Push 'eddl-toolkit' images
	$(eval EDDL_IMAGE_VERSION_TAG := $(or ${EDDL_IMAGE_VERSION_TAG},${EDDL_REVISION}))
	$(call push_image,eddl-toolkit,${EDDL_IMAGE_VERSION_TAG})

push_ecvl_toolkit: repo-login ecvl_folder ## Push 'ecvl-toolkit' images
	$(eval ECVL_IMAGE_VERSION_TAG := $(or ${ECVL_IMAGE_VERSION_TAG},${ECVL_REVISION}))
	$(call push_image,ecvl-toolkit,${ECVL_IMAGE_VERSION_TAG})

push_pylibs: repo-login ## Push 'pylibs' images
	$(call push_image,pylibs)

push_pyeddl: repo-login pyeddl_folder ## Push 'pyeddl' images
	$(eval PYEDDL_IMAGE_VERSION_TAG := $(or ${PYEDDL_IMAGE_VERSION_TAG},${PYEDDL_REVISION}))
	$(call push_image,pyeddl,${PYEDDL_IMAGE_VERSION_TAG})

push_pyecvl: repo-login pyecvl_folder ## Push 'pyecvl' images
	$(eval PYECVL_IMAGE_VERSION_TAG := $(or ${PYECVL_IMAGE_VERSION_TAG},${PYECVL_REVISION}))
	$(call push_image,pyecvl,${PYECVL_IMAGE_VERSION_TAG})

push_pylibs_toolkit: repo-login ## Push 'pylibs-toolkit' images
	$(call push_image,pylibs-toolkit)

push_pyeddl_toolkit: repo-login pyeddl_folder ## Push 'pyeddl-toolkit' images
	$(eval PYEDDL_IMAGE_VERSION_TAG := $(or ${PYEDDL_IMAGE_VERSION_TAG},${PYEDDL_REVISION}))
	$(call push_image,pyeddl-toolkit,${PYEDDL_IMAGE_VERSION_TAG})

push_pyecvl_toolkit: repo-login pyecvl_folder ## Push 'pyeddl-toolkit' images
	$(eval PYECVL_IMAGE_VERSION_TAG := $(or ${PYECVL_IMAGE_VERSION_TAG},${PYECVL_REVISION}))
	$(call push_image,pyecvl-toolkit,${PYECVL_IMAGE_VERSION_TAG})

############################################################################################################################
### Piblish Docker images
############################################################################################################################
publish: build push ## Publish all built images to a Docker Registry (e.g., DockerHub)

publish_libs: build_libs push_libs ## Publish 'libs' images

publish_eddl: build_eddl push_eddl ## Publish 'eddl' images

publish_ecvl: build_ecvl push_ecvl ## Publish 'ecvl' images

publish_libs_toolkit: build_libs_toolkit push_libs_toolkit ## Publish 'libs-toolkit' images

publish_eddl_toolkit: build_eddl_toolkit push_eddl_toolkit ## Publish 'eddl-toolkit' images

publish_ecvl_toolkit: build_ecvl_toolkit push_ecvl_toolkit ## Publish 'ecvl-toolkit' images

publish_pylibs: build_pylibs push_pylibs ## Publish 'pylibs' images

publish_pyeddl: build_pyeddl push_pyeddl ## Publish 'pyeddl' images

publish_pyecvl: build_pyecvl push_pyecvl ## Publish 'pyecvl' images

publish_pylibs_toolkit: build_pylibs_toolkit push_pylibs_toolkit ## Publish 'pylibs-toolkit' images

publish_pyeddl_toolkit: build_pyeddl_toolkit push_pyeddl_toolkit ## Publish 'pyeddl-toolkit' images

publish_pyecvl_toolkit: build_pyecvl_toolkit push_pyecvl_toolkit ## Publish 'pyecvl-toolkit' images

# login to the Docker HUB repository
_repo-login: ## Login to the Docker Registry
	@if [[ ${DOCKER_LOGIN_DONE} == false ]]; then \
		echo "Logging into Docker registry ${DOCKER_REGISTRY}..." ; \
		echo ${DOCKER_PASSWORD} | docker login ${DOCKER_REGISTRY} --username ${DOCKER_USER} --password-stdin \
	else \
		echo "Logging into Docker registry already done" ; \
	fi

repo-login: _repo-login ## Login to the Docker Registry
	$(eval DOCKER_LOGIN_DONE := true)


version: ## Output the current version of this Makefile
	@echo $(VERSION)


############################################################################################################################
### Clean sources
############################################################################################################################
clean_eddl_sources:
	$(call clean_sources,libs/eddl)

clean_ecvl_sources:
	$(call clean_sources,libs/ecvl)

clean_pyeddl_sources:
	$(call clean_sources,pylibs/pyeddl)

clean_pyecvl_sources:
	$(call clean_sources,pylibs/pyecvl)

clean_libs_sources: clean_eddl_sources clean_ecvl_sources

clean_pylibs_sources: clean_pyeddl_sources clean_pyecvl_sources

clean_sources: clean_pylibs_sources clean_libs_sources


############################################################################################################################
### Clean Docker images
############################################################################################################################
clean_base_images:
	$(call clean_image,libs-base)
	$(call clean_image,pylibs-base)
	$(call clean_image,libs-base-toolkit)
	$(call clean_image,pylibs-base-toolkit)

clean_eddl_images:
	$(call clean_image,eddl)
	$(call clean_image,eddl-toolkit)

clean_ecvl_images:
	$(call clean_image,ecvl)
	$(call clean_image,ecvl-toolkit)

clean_libs_images: clean_ecvl_images clean_eddl_images
	$(call clean_image,libs)
	$(call clean_image,libs-toolkit)

clean_pyeddl_images:
	$(call clean_image,pyeddl)
	$(call clean_image,pyeddl-toolkit)

clean_pyecvl_images:
	$(call clean_image,pyecvl)
	$(call clean_image,pyecvl-toolkit)

clean_pylibs_images: clean_pyecvl_images clean_pyeddl_images
	$(call clean_image,pylibs)
	$(call clean_image,pylibs-toolkit)

clean_images: clean_pylibs_images clean_libs_images clean_base_images


############################################################################################################################
### Clean Docker images
############################################################################################################################
clean: clean_images clean_sources



.PHONY: help \
	libs_folder eddl_folder ecvl_folder pylibs_folder \
	pyeddl_folder _pyeddl_shallow_clone \
	pyecvl_folder _pyeddl_shallow_clone _pyecvl_first_level_dependencies _pyecvl_second_level_dependencies \
	apply_pyeddl_patches apply_pyecvl_patches \
	clean clean_libs clean_pylibs apply_libs_patches \
	build _build \
	_build_libs_base_toolkit \
	build_eddl_toolkit build_ecvl_toolkit build_libs_toolkit \
	_build_libs_base build_eddl build_ecvl build_libs \
	_build_pylibs_base_toolkit _build_pylibs_base \
	build_pyeddl_toolkit build_pyecvl_toolkit build_pylibs_toolkit\
	_build_pylibs_base build_pyeddl build_pyecvl build_pylibs \
	repo-login \
	push _push \
	push_libs push_eddl push_ecvl \
	push_libs_toolkit push_eddl_toolkit push_ecvl_toolkit \
	push_pylibs push_pyeddl push_pyecvl \
	push_pylibs_toolkit push_pyeddl_toolkit push_pyecvl_toolkit \
	publish \
	publish_libs publish_eddl publish_ecvl \
	publish_libs_toolkit publish_eddl_toolkit publish_ecvl_toolkit \
	publish_pylibs publish_pyeddl publish_pyecvl \
	publish_pylibs_toolkit publish_pyeddl_toolkit publish_pyecvl_toolkit \
	clean_sources \
	clean_eddl_sources clean_ecvl_sources \
	clean_pyeddl_sources clean_pyecvl_sources \
	clean \
	clean_images \
	clean_base_images \
	clean_eddl_images clean_ecvl_images clean_libs_images \
	clean_pyeddl_images clean_pyecvl_images clean_pylibs_images