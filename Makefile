# set bash as default interpreter
SHELL := /bin/bash

# detect OS
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Linux)
	XARGS_OPT = --no-run-if-empty
endif
ifeq ($(UNAME_S),Darwin)
	XARGS_OPT =
endif

# config file
CONFIG_FILE ?= settings.conf
ifneq ($(wildcard $(CONFIG_FILE)),)
include $(CONFIG_FILE)
endif

# date.time as build number
BUILD_NUMBER := $(or ${BUILD_NUMBER},$(shell date '+%Y%m%d.%H%M%S'))

# set build target: (CPU, GPU)
BUILD_TARGET := $(or $(BUILD_TARGET),CPU)
build_target_opts := --build-arg BUILD_TARGET=$(BUILD_TARGET)

# log file with dependencies
IMAGES_LOG := .images.log
LIBRARIES_LOG := .libraries.log
DEPENDENCIES_LOG := .dependencies.log
DEPENDENCY_GRAPH_FILE := graph.dot

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

# extract info about repository revision 
LIBS_TAG := $(shell git tag -l --points-at HEAD | tail -n 1)
LIBS_REVISION := $(shell git rev-parse --short HEAD | sed -E 's/-//; s/ .*//')
LIBS_BRANCH := $(shell git name-rev --name-only HEAD | sed -E 's+(remotes/|origin/)++g; s+/+-+g; s/ .*//')
LIBS_VERSION := $(shell if [[ -n "${LIBS_TAG}" ]]; then echo ${LIBS_TAG}; else echo ${LIBS_REVISION}; fi)

# set container version equal to the repository version
CONTAINER_VERSION := $(LIBS_VERSION)

# set base image version
DOCKER_BASE_IMAGE_VERSION := ${DOCKER_BASE_IMAGE_VERSION}

# latest tag settings
DOCKER_IMAGE_LATEST := $(or ${DOCKER_IMAGE_LATEST},false)

# extra tags
DOCKER_IMAGE_TAG_EXTRA := ${DOCKER_IMAGE_TAG_EXTRA}

# set tag suffix
DOCKER_IMAGE_TAG_SUFFIX := $(shell [[ "$(ENABLE_TARGET_SUFFIX_IMAGE_TAG)" == "true" ]] && echo -$(BUILD_TARGET) | tr '[:upper:]' '[:lower:]')

# set default Docker image TAG
DOCKER_IMAGE_TAG := $(or ${DOCKER_IMAGE_TAG},${BUILD_NUMBER})

# set docker-libs version tag
DOCKER_LIBS_IMAGE_VERSION_TAG := $(or ${LIBS_IMAGE_VERSION_TAG},${LIBS_TAG},${LIBS_VERSION})$(DOCKER_IMAGE_TAG_SUFFIX)
DOCKER_LIBS_EXTRA_TAGS := $(LIBS_VERSION)$(DOCKER_IMAGE_TAG_SUFFIX) $(LIBS_REVISION)$(DOCKER_IMAGE_TAG_SUFFIX)

# set default Base images
DOCKER_BASE_IMAGE_SKIP_PULL := $(or ${DOCKER_BASE_IMAGE_SKIP_PULL},true)
DOCKER_UBUNTU_IMAGE := $(or ${DOCKER_UBUNTU_IMAGE},ubuntu:18.04)
DOCKER_NVIDIA_DEVELOP_IMAGE := $(or ${DOCKER_NVIDIA_DEVELOP_IMAGE},nvidia/cuda:10.1-devel-ubuntu18.04)
DOCKER_NVIDIA_RUNTIME_IMAGE := $(or ${DOCKER_NVIDIA_RUNTIME_IMAGE},nvidia/cuda:10.1-runtime-ubuntu18.04)

# extract name and tag of nvidia images
DOCKER_UBUNTU_IMAGE_NAME := $(shell echo ${DOCKER_UBUNTU_IMAGE} | sed -e 's+:.*++')
DOCKER_UBUNTU_IMAGE_TAG := $(shell echo ${DOCKER_UBUNTU_IMAGE} | sed -E 's@.+:(.+)@\1@')
DOCKER_NVIDIA_DEVELOP_IMAGE_NAME := $(shell echo ${DOCKER_NVIDIA_DEVELOP_IMAGE} | sed -e 's+:.*++')
DOCKER_NVIDIA_DEVELOP_IMAGE_TAG := $(shell echo ${DOCKER_NVIDIA_DEVELOP_IMAGE} | sed -E 's@.+:(.+)@\1@')
DOCKER_NVIDIA_RUNTIME_IMAGE_NAME := $(shell echo ${DOCKER_NVIDIA_RUNTIME_IMAGE} | sed -e 's+:.*++')
DOCKER_NVIDIA_RUNTIME_IMAGE_TAG := $(shell echo ${DOCKER_NVIDIA_RUNTIME_IMAGE} | sed -E 's@.+:(.+)@\1@')

DOCKER_BASE_IMAGE_VERSION_TAG := $(CONTAINER_VERSION)$(DOCKER_IMAGE_TAG_SUFFIX)
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
ECVL_TAG :=

# PyECVL repository
PYECVL_REPOSITORY := $(or ${PYECVL_REPOSITORY},https://github.com/deephealthproject/pyecvl.git)
PYECVL_BRANCH := $(or ${PYECVL_BRANCH},master)
PYECVL_REVISION := ${PYECVL_REVISION}
PYECVL_TAG :=

# EDDL repository
EDDL_REPOSITORY := $(or ${EDDL_REPOSITORY},https://github.com/deephealthproject/eddl.git)
EDDL_BRANCH := $(or ${EDDL_BRANCH},master)
EDDL_REVISION := ${EDDL_REVISION}
EDDL_TAG :=

# PyEDDL repository
PYEDDL_REPOSITORY := $(or ${PYEDDL_REPOSITORY},https://github.com/deephealthproject/pyeddl.git)
PYEDDL_BRANCH := $(or ${PYEDDL_BRANCH},master)
PYEDDL_REVISION := ${PYEDDL_REVISION}
PYEDDL_TAG :=

# disable image pull
DISABLE_PULL ?= 0
_DO_NOT_PULL_DOCKER_IMAGES = 0
ifeq ($(DISABLE_PULL),$(filter $(DISABLE_PULL),1 true TRUE))
$(info Docker image pull disabled)
_DO_NOT_PULL_DOCKER_IMAGES = 1
endif

# set no cache option
DISABLE_CACHE ?= 0
BUILD_CACHE_OPT ?=
ifeq ($(DISABLE_CACHE),$(filter $(DISABLE_CACHE),1 true TRUE))
$(info Docker cache disabled)
BUILD_CACHE_OPT = --no-cache
_DO_NOT_USE_DOCKER_CACHE = 1
endif

# enable latest tags
push_latest_tags = false
ifeq ($(DOCKER_IMAGE_LATEST),$(filter $(DOCKER_IMAGE_LATEST),1 true TRUE))
	push_latest_tags = true
endif

# auxiliary flag 
DOCKER_LOGIN_DONE := $(or ${DOCKER_LOGIN_DONE},false)

# Arguments to execute tests with Docker
DOCKER_RUN := docker run -i --rm #-u 1000:1000
ifneq (${GPU_RUNTIME},)
	DOCKER_RUN := ${DOCKER_RUN} ${GPU_RUNTIME}
endif

define build_new_image
	echo "Building Docker image '${image_name}' ( tags: ${tag} ${extra_tags})..." ; \
	$(eval tags := $(filter-out undefined,$(foreach tag,$(extra_tags),-t $(image_name):$(tag))))
	$(eval _DO_NOT_PULL_DOCKER_IMAGES := 1)
	cd ${image} \
	&& docker build ${BUILD_CACHE_OPT} \
		-f ${target}.Dockerfile \
		${base} ${toolkit} ${extra_args} \
		-t ${image_name}:${tag} ${tags} ${latest_tags} ${labels} . 
endef

define build_image
	$(eval image := $(1))
	$(eval target := $(2))
	$(eval tag := $(3))
	$(eval labels := $(4))
	$(eval base := $(if $(5), --build-arg BASE_IMAGE=$(5)))
	$(eval toolkit := $(if $(6), --build-arg TOOLKIT_IMAGE=$(6)))
	$(eval extra_tags := $(7))
	$(eval extra_args := $(8))
	$(eval image_name := ${DOCKER_IMAGE_PREFIX}${target}${${target}_suffix})
	$(eval full_image_name := $(shell prefix=""; if [ -n "${DOCKER_REGISTRY}" ]; then prefix="${DOCKER_REGISTRY}/"; fi; echo "${prefix}${DOCKER_REPOSITORY_OWNER}/${image_name}"))
	$(eval latest_tags := $(shell if [ "${push_latest_tags}" == "true" ]; then echo "-t ${image_name}:latest"; fi))
	$(eval tagged_image := ${image_name}:${tag})
	$(eval images := $(shell docker images -q ${tagged_image}))
	$(eval exists := $(shell curl --silent -f -lSL https://index.docker.io/v1/repositories/${full_image_name}/tags/${tag} 2>/dev/null))
	@printf "\n\n" ; \
	$(if $(or $(findstring ${_DO_NOT_USE_DOCKER_CACHE},1),$(findstring ${_DO_NOT_PULL_DOCKER_IMAGES},1)),\
		$(call build_new_image),
		$(if ${images},\
			@echo "Docker image '${tagged_image}' exists (id: ${images})", \
			$(if $(and ${exists},$(findstring ${_DO_NOT_PULL_DOCKER_IMAGES},0)), \
				@echo "Pulling image '${full_image_name}:${tag}'..."; 
				docker pull ${full_image_name}:${tag} && docker tag ${full_image_name}:${tag} ${tagged_image}, \
				@echo "Docker image '${full_image_name}:${tag}' doesn't exist", \
				$(call build_new_image)
			)
		)
	)
	$(call log_image_revision,$(target),$(tag),extend,$(shell echo $(5)))
	$(if $(6),$(call log_image_revision,$(target),$(tag),use,$(shell echo $(6))))
endef

define push_image
	$(eval image := $(1))
	$(eval tag := $(or $(2),${DOCKER_IMAGE_TAG}))
	$(eval extra_tags := $(filter-out $(tag),$(foreach t,$(3) ${DOCKER_IMAGE_TAG_EXTRA},$(t))))
	$(eval image_name := ${DOCKER_IMAGE_PREFIX}${image})
	$(eval full_image_name := $(shell prefix=""; if [ -n "${DOCKER_REGISTRY}" ]; then prefix="${DOCKER_REGISTRY}/"; fi; echo "${prefix}${DOCKER_REPOSITORY_OWNER}/${image_name}"))
	$(eval full_tag := ${full_image_name}:$(tag))
	$(eval latest_tag := ${full_image_name}:latest)
	@echo "Tagging images... "
	docker tag ${image_name}:$(tag) ${full_tag}
	@if [ ${push_latest_tags} == true ]; then docker tag ${image_name}:$(tag) ${latest_tag}; fi
	@echo "Pushing Docker image '${image_name}'..."	
	docker push ${full_tag}
	@if [ ${push_latest_tags} == true ]; then docker push ${latest_tag}; fi
	@for tag in $(extra_tags); \
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
	@docker ps -a | grep -E "^$(image)\s" | awk '{print $$1}' | xargs ${XARGS_OPT} docker rm -f  || true
	@printf "DONE\n"
	@printf "Removing docker image '$(image)'... "
	@docker images | grep -E "^$(image)\s" | awk '{print $$1 ":" $$2}' | xargs ${XARGS_OPT} docker rmi -f  || true
	@docker images | grep -E "^${DOCKER_REPOSITORY_OWNER}/$(image)\s" | awk '{print $$1 ":" $$2}' | xargs ${XARGS_OPT} docker rmi -f  || true
	@printf "DONE\n"
	@printf "Removing unused docker image... "
	@docker image prune -f
	@printf "DONE\n"
endef


# 1: library path
define get_tag
	$(eval tag := $(shell cd ${1} && git tag -l --points-at HEAD | tail -n 1)) \
	$(strip $(shell echo ${tag};))
endef

# 1: library path
define get_revision
	$(eval head := $(shell cd ${1} && git rev-parse --short HEAD | sed -E 's/-//; s/ .*//')) \
	$(strip $(shell echo ${head};))
endef

# 1: submodule path
# 2: library name
# 3: revision
define submodule_revision
	$(eval rev = $(shell cd $(1) && git submodule status -- $(2) | sed -E 's/-//; s/ .*//' | cut -c1-7;)) \
	$(shell if [[ -n "$(3)" ]]; then echo $(3); else echo $(rev); fi)
endef

# 1: library path
# 2: library name
define set_library_revision
	$(eval lib := $(shell echo $(2) | tr a-z A-Z))
	$(eval ${lib}_REVISION := $(call get_revision,$(1)/$(2)))
	$(eval $(lib)_TAG = $(call get_tag,$(1)/$(2)))
	$(eval ${lib}_IMAGE_VERSION_TAG = $(or $(filter %-cpu %-gpu,$(${lib}_IMAGE_VERSION_TAG)),$(or ${${lib}_IMAGE_VERSION_TAG},${${lib}_TAG},${${lib}_REVISION})$(DOCKER_IMAGE_TAG_SUFFIX)))
	@echo "${lib} rev: ${${lib}_REVISION} ${${lib}_TAG} (image-tag: ${${lib}_IMAGE_VERSION_TAG})"
endef

define log_library_revision
	$(file >>${LIBRARIES_LOG},$(1) [label="$(1) (rev. ${$(1)_REVISION} ${$(1)_TAG})"];) \
	$(if $(2),$(file >>${DEPENDENCIES_LOG},$(2) -> $(1) [label=" << depends on >> ",color="black:invis:black"];))
endef

define log_image_revision
	$(eval A := $(shell echo $(1):$(2) | sed -e 's+[-:/\.]+_+g'))
	$(eval B := $(shell echo $(4) | sed -e 's+[-:/\.]+_+g'))
	$(eval relation_style := $(shell \
	if [[ "$(3)" == "install" ]]; then echo 'style=dashed,color="black"' ; \
	elif [[ "$(3)" == "extend" ]]; then echo 'color="black"' ; \
	elif [[ "$(3)" == "use" ]]; then echo 'style=dotted,color="black"' ; \
	else echo "style=dotted,color=gray" ; fi \
	))
	$(file >>${IMAGES_LOG},${A} [label="$(1) (tag. $(2))"];) \
	$(if $(4),$(file >>${DEPENDENCIES_LOG},$(A) -> $(B) [label=" << $(3) >> ",$(relation_style)];))
endef

.DEFAULT_GOAL := help

# version
version: ## Output the current version of this Makefile
	@echo $(LIBS_VERSION)

help: ## Show help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

libraries_list:
	@sort -u ${LIBRARIES_LOG}

images_list:
	@sort -u ${IMAGES_LOG}

dependencies_list:
	@sort -u ${DEPENCIES_LOG}

dependency_graph: ## make a dependency graph of the involved libraries
	@echo "digraph {"  > ${DEPENDENCY_GRAPH_FILE} \
	&& sort -u ${LIBRARIES_LOG} >> ${DEPENDENCY_GRAPH_FILE} \
	&& sort -u ${IMAGES_LOG} >> ${DEPENDENCY_GRAPH_FILE} \
	&& sort -u ${DEPENDENCIES_LOG} >> ${DEPENDENCY_GRAPH_FILE} \
	&& echo "}" >> ${DEPENDENCY_GRAPH_FILE}  \
	&& if [[ $$(command -v dot) ]]; then \
	dot -Tpdf ${DEPENDENCY_GRAPH_FILE} -o ${DEPENDENCY_GRAPH_FILE}.pdf; \
	fi

#####################################################################################################################################
############# Clone sources #############
#####################################################################################################################################

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
	$(call set_library_revision,libs,eddl) \
	$(call log_library_revision,EDDL)


define clone_ecvl
	$(if $(wildcard ${ECVL_LIB_PATH}),$(info Using existing '${ECVL_LIB_PATH}' repository), \
		$(call clone_repository,${ECVL_LIB_PATH},${ECVL_REPOSITORY},${ECVL_BRANCH},${ECVL_REVISION},true) ; \
	)
endef

_ecvl_folder:
	$(call clone_ecvl)

ecvl_folder: _ecvl_folder pyecvl_folder
	$(call set_library_revision,libs,ecvl) \
	$(call log_library_revision,ECVL)

pylibs_folder:
	@mkdir -p ${LOCAL_PYLIBS_PATH}

define pyeddl_shallow_clone
	$(if $(wildcard ${PYEDDL_LIB_PATH}),$(info Using existing '${PYEDDL_LIB_PATH}' repository), \
		$(call clone_repository,${PYEDDL_LIB_PATH},${PYEDDL_REPOSITORY},${PYEDDL_BRANCH},${PYEDDL_REVISION},false) ; \
	)
endef

define pyeddl_clone_dependencies
	$(eval EDDL_REVISION = $(call submodule_revision,${PYEDDL_LIB_PATH}/third_party,eddl,${EDDL_REVISION}))
	if [[ -d ${EDDL_LIB_PATH} ]]; then \
		echo "Using existing '${EDDL_LIB_PATH}' repository" ; \
	else \
		$(call clone_repository,${EDDL_LIB_PATH},${EDDL_REPOSITORY},${EDDL_BRANCH},${EDDL_REVISION},true) ; \
		printf "Copying revision '${EDDL_REVISION}' of EDDL library... " ; \
		rm -rf ${PYEDDL_LIB_PATH}/third_party/eddl && cp -a ${EDDL_LIB_PATH} ${PYEDDL_LIB_PATH}/third_party/eddl ; \
		printf "DONE\n" ; \
		$(call log_library_revision,EDDL,PYEDDL) \
	fi
endef

_pyeddl_shallow_clone: pylibs_folder
	$(call pyeddl_shallow_clone)

_pyeddl_dependencies: _pyeddl_shallow_clone
	$(call pyeddl_clone_dependencies)

pyeddl_folder: _pyeddl_dependencies
	$(call set_library_revision,libs,eddl) \
	$(call set_library_revision,pylibs,pyeddl) \
	$(call log_library_revision,PYEDDL)

define pyecvl_shallow_clone
	$(if $(wildcard ${PYECVL_LIB_PATH}),$(info Using existing '${PYECVL_LIB_PATH}' repository), \
		$(call clone_repository,${PYECVL_LIB_PATH},${PYECVL_REPOSITORY},${PYECVL_BRANCH},${PYECVL_REVISION},false) ; \
	)
endef

define pyecvl_resolve_dependencies
	$(eval PYEDDL_REVISION = $(call submodule_revision,${PYECVL_LIB_PATH}/third_party,pyeddl,${PYEDDL_REVISION}))
	$(eval ECVL_REVISION = $(call submodule_revision,${PYECVL_LIB_PATH}/third_party,ecvl,${ECVL_REVISION}))
	$(call log_library_revision,PYEDDL,PYECVL) \
	$(call log_library_revision,ECVL,PYECVL) \
	if [[ -d ${PYEDDL_LIB_PATH} ]]; then \
		echo "Using existing '${PYEDDL_LIB_PATH}' repository" ; \
	else \
		$(call pyeddl_shallow_clone) \
		printf "Copying revision '${PYEDDL_REVISION}' of PYEDDL library... " ; \
		rm -rf ${PYECVL_LIB_PATH}/third_party/pyeddl && cp -a ${PYEDDL_LIB_PATH} ${PYECVL_LIB_PATH}/third_party/pyeddl ; \
		printf "DONE\n" ; \
		$(call log_library_revision,PYEDDL,PYECVL) \
	fi
	if [[ -d ${ECVL_LIB_PATH} ]]; then \
		echo "Using existing '${ECVL_LIB_PATH}' repository" ; \
	else \
		echo "Using ECVL revision '${ECVL_REVISION}'" ; \
		$(call clone_ecvl) \
		printf "Copying revision '${ECVL_REVISION}' of ECVL library... " ; \
		rm -rf ${PYECVL_LIB_PATH}/third_party/ecvl && cp -a ${ECVL_LIB_PATH} ${PYECVL_LIB_PATH}/third_party/ecvl ; \
		printf "DONE\n" ; \
		$(call log_library_revision,ECVL,PYECVL) \
	fi
endef

_pyecvl_shallow_clone: pylibs_folder
	$(call pyecvl_shallow_clone)

_pyecvl_first_level_dependencies: _pyecvl_shallow_clone
	$(call pyecvl_resolve_dependencies)

_pyecvl_second_level_dependencies: _pyecvl_first_level_dependencies
	$(call set_library_revision,libs,ecvl) \
	$(call set_library_revision,pylibs,pyeddl) \
	$(call pyeddl_clone_dependencies)

pyecvl_folder: _pyecvl_second_level_dependencies
	$(call set_library_revision,pylibs,pyecvl)
	$(call log_library_revision,PYECVL)

# TODO: remove this patch when not required
apply_pyeddl_patches: pyeddl_folder
	@echo "Applying patches to the EDDL repository..."
	cd ${EDDL_LIB_PATH} && git apply ../../${PYEDDL_LIB_PATH}/eddl_0.3.patch || true

# # TODO: remove this patch when not required
apply_pyecvl_patches:


#####################################################################################################################################
############# Build Docker images #############
#####################################################################################################################################
# Targets to build container images
build: _build ## Build all Docker images
_build: \
	build_eddl build_ecvl build_libs \
	build_eddl_toolkit build_ecvl_toolkit build_libs_toolkit \
	build_pyeddl build_pyecvl build_pylibs \
	build_pyeddl_toolkit build_pyecvl_toolkit build_pylibs_toolkit

############# libs-toolkit #############

_build_libs_base_toolkit:
	$(if $(findstring $(BUILD_TARGET), GPU),\
		echo "Building for GPU"; \
		$(call build_image,libs,libs-base-toolkit,${DOCKER_BASE_IMAGE_VERSION_TAG}, --label CONTAINER_VERSION=$(CONTAINER_VERSION),$(DOCKER_NVIDIA_DEVELOP_IMAGE),,,${build_target_opts}) \
		$(call log_image_revision,$(DOCKER_NVIDIA_DEVELOP_IMAGE_NAME),$(DOCKER_NVIDIA_DEVELOP_IMAGE_TAG)),\
		echo "Building for CPU"; \
		$(call build_image,libs,libs-base-toolkit,${DOCKER_BASE_IMAGE_VERSION_TAG}, --label CONTAINER_VERSION=$(CONTAINER_VERSION),$(DOCKER_UBUNTU_IMAGE),,,${build_target_opts}) \
		$(call log_image_revision,$(DOCKER_UBUNTU_IMAGE_NAME),$(DOCKER_UBUNTU_IMAGE_TAG)) \
	)

build_eddl_toolkit: eddl_folder _build_libs_base_toolkit apply_pyeddl_patches ## Build 'eddl-toolkit' image
	$(call build_image,libs,eddl-toolkit,${EDDL_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION) \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION},libs-base-toolkit:$(DOCKER_BASE_IMAGE_VERSION_TAG))
	$(call log_image_revision,eddl-toolkit,${EDDL_IMAGE_VERSION_TAG},install,EDDL)

build_ecvl_toolkit: ecvl_folder build_eddl_toolkit ## Build 'ecvl-toolkit' image
	$(call build_image,libs,ecvl-toolkit,${ECVL_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION) \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION},eddl-toolkit:$(EDDL_IMAGE_VERSION_TAG))
	$(call log_image_revision,ecvl-toolkit,${ECVL_IMAGE_VERSION_TAG},install,ECVL)

build_libs_toolkit: build_ecvl_toolkit ## Build 'libs-toolkit' image
	$(call build_image,libs,libs-toolkit,${DOCKER_LIBS_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION) \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION},ecvl-toolkit:$(ECVL_IMAGE_VERSION_TAG),,${DOCKER_LIBS_EXTRA_TAGS})


############# libs #############

_build_libs_base: _build_libs_base_toolkit
	$(if $(findstring $(BUILD_TARGET), GPU),\
		$(call build_image,libs,libs-base,${DOCKER_BASE_IMAGE_VERSION_TAG},\
			--label CONTAINER_VERSION=$(CONTAINER_VERSION),$(DOCKER_NVIDIA_RUNTIME_IMAGE),libs-base-toolkit:$(DOCKER_BASE_IMAGE_VERSION_TAG),,${build_target_opts})\
		$(call log_image_revision,$(DOCKER_NVIDIA_RUNTIME_IMAGE_NAME),$(DOCKER_NVIDIA_RUNTIME_IMAGE_TAG)),\
		$(call build_image,libs,libs-base,${DOCKER_BASE_IMAGE_VERSION_TAG},\
			--label CONTAINER_VERSION=$(CONTAINER_VERSION),$(DOCKER_UBUNTU_IMAGE),libs-base-toolkit:$(DOCKER_BASE_IMAGE_VERSION_TAG),,${build_target_opts})\
		$(call log_image_revision,$(DOCKER_UBUNTU_IMAGE_NAME),$(DOCKER_UBUNTU_IMAGE_TAG))\
	)

build_eddl: _build_libs_base build_eddl_toolkit ## Build 'eddl' image
	$(call build_image,libs,eddl,${EDDL_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION) \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION},libs-base:$(DOCKER_BASE_IMAGE_VERSION_TAG),eddl-toolkit:$(EDDL_IMAGE_VERSION_TAG))
	$(call log_image_revision,eddl,${EDDL_IMAGE_VERSION_TAG},install,EDDL)

build_ecvl: _build_libs_base build_ecvl_toolkit build_eddl ## Build 'ecvl' image
	$(call build_image,libs,ecvl,${ECVL_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION) \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION},eddl:$(EDDL_IMAGE_VERSION_TAG),ecvl-toolkit:$(ECVL_IMAGE_VERSION_TAG))
	$(call log_image_revision,ecvl,${ECVL_IMAGE_VERSION_TAG},install,ECVL)

build_libs: build_ecvl ## Build 'libs' image
	$(call build_image,libs,libs,${DOCKER_LIBS_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION) \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION},ecvl:$(ECVL_IMAGE_VERSION_TAG),,${DOCKER_LIBS_EXTRA_TAGS})



############# pylibs-toolkit #############

_build_pyeddl_base_toolkit: build_eddl_toolkit
	$(eval PYLIBS_BASE_IMAGE_VERSION_TAG := base_${DOCKER_BASE_IMAGE_VERSION_TAG}-eddl_${EDDL_IMAGE_VERSION_TAG})
	$(call build_image,pylibs,pylibs-base-toolkit,${PYLIBS_BASE_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION),eddl-toolkit:$(EDDL_IMAGE_VERSION_TAG))

_build_pyecvl_base_toolkit: build_ecvl_toolkit pyeddl_folder apply_pyeddl_patches
	$(eval PYLIBS_BASE_IMAGE_VERSION_TAG := base_${DOCKER_BASE_IMAGE_VERSION_TAG}-pyeddl_eddl_${PYEDDL_IMAGE_VERSION_TAG}-eddl_${EDDL_IMAGE_VERSION_TAG}-ecvl_${ECVL_IMAGE_VERSION_TAG})
	$(call build_image,pylibs,pylibs-base-toolkit,${PYLIBS_BASE_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION),ecvl-toolkit:$(ECVL_IMAGE_VERSION_TAG))
	$(call build_image,pylibs,pyeddl-toolkit,${PYLIBS_BASE_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION) \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION} \
		--label PYEDDL_REPOSITORY=${PYEDDL_REPOSITORY} \
		--label PYEDDL_BRANCH=${PYEDDL_BRANCH} \
		--label PYEDDL_REVISION=${PYEDDL_REVISION},pylibs-base-toolkit:$(PYLIBS_BASE_IMAGE_VERSION_TAG))
	$(call log_image_revision,pyeddl-toolkit,${PYLIBS_BASE_IMAGE_VERSION_TAG},install,PYEDDL)

build_pyeddl_toolkit: pyeddl_folder _build_pyeddl_base_toolkit apply_pyeddl_patches ## Build 'pyeddl-toolkit' image
	$(call build_image,pylibs,pyeddl-toolkit,${PYEDDL_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION) \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION} \
		--label PYEDDL_REPOSITORY=${PYEDDL_REPOSITORY} \
		--label PYEDDL_BRANCH=${PYEDDL_BRANCH} \
		--label PYEDDL_REVISION=${PYEDDL_REVISION},pylibs-base-toolkit:$(PYLIBS_BASE_IMAGE_VERSION_TAG))
	$(call log_image_revision,pyeddl-toolkit,${PYEDDL_IMAGE_VERSION_TAG},install,PYEDDL)

build_pyecvl_toolkit: pyecvl_folder _build_pyecvl_base_toolkit ## Build 'pyecvl-toolkit' image
	$(call build_image,pylibs,pyecvl-toolkit,${PYECVL_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION) \
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
		--label PYEDDL_REVISION=${PYEDDL_REVISION},pyeddl-toolkit:$(PYLIBS_BASE_IMAGE_VERSION_TAG))
	$(call log_image_revision,pyecvl-toolkit,${PYECVL_IMAGE_VERSION_TAG},install,PYECVL)

build_pylibs_toolkit: build_pyecvl_toolkit ## Build 'pylibs-toolkit' image
	$(call build_image,pylibs,pylibs-toolkit,${DOCKER_LIBS_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION) \
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
		--label PYEDDL_REVISION=${PYEDDL_REVISION},pyecvl-toolkit:$(PYECVL_IMAGE_VERSION_TAG),,${DOCKER_LIBS_EXTRA_TAGS})



############# pylibs #############

_build_pyeddl_base: build_eddl
	$(eval PYLIBS_BASE_IMAGE_VERSION_TAG := base_${DOCKER_BASE_IMAGE_VERSION_TAG}-eddl_${EDDL_IMAGE_VERSION_TAG})
	$(call build_image,pylibs,pylibs-base,${PYLIBS_BASE_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION),eddl:$(EDDL_IMAGE_VERSION_TAG))

_build_pyecvl_base: build_ecvl
	$(eval PYLIBS_BASE_IMAGE_VERSION_TAG := base_${DOCKER_BASE_IMAGE_VERSION_TAG}-pyeddl_${PYEDDL_IMAGE_VERSION_TAG}-eddl_${EDDL_IMAGE_VERSION_TAG}-ecvl_${ECVL_IMAGE_VERSION_TAG})
	$(call build_image,pylibs,pylibs-base,${PYLIBS_BASE_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION),ecvl:$(ECVL_IMAGE_VERSION_TAG))
	$(call build_image,pylibs,pyeddl,${PYLIBS_BASE_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION) \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION} \
		--label PYEDDL_REPOSITORY=${PYEDDL_REPOSITORY} \
		--label PYEDDL_BRANCH=${PYEDDL_BRANCH} \
		--label PYEDDL_REVISION=${PYEDDL_REVISION},pylibs-base:$(PYLIBS_BASE_IMAGE_VERSION_TAG),pyeddl-toolkit:$(PYEDDL_IMAGE_VERSION_TAG))
	$(call log_image_revision,pyeddl,${PYLIBS_BASE_IMAGE_VERSION_TAG},install,PYEDDL)

build_pyeddl: build_pyeddl_toolkit _build_pyeddl_base ## Build 'pyeddl' image
	$(call build_image,pylibs,pyeddl,${PYEDDL_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION) \
		--label EDDL_REPOSITORY=${EDDL_REPOSITORY} \
		--label EDDL_BRANCH=${EDDL_BRANCH} \
		--label EDDL_REVISION=${EDDL_REVISION} \
		--label ECVL_REPOSITORY=${ECVL_REPOSITORY} \
		--label ECVL_BRANCH=${ECVL_BRANCH} \
		--label ECVL_REVISION=${ECVL_REVISION} \
		--label PYEDDL_REPOSITORY=${PYEDDL_REPOSITORY} \
		--label PYEDDL_BRANCH=${PYEDDL_BRANCH} \
		--label PYEDDL_REVISION=${PYEDDL_REVISION},pylibs-base:$(PYLIBS_BASE_IMAGE_VERSION_TAG),pyeddl-toolkit:$(PYEDDL_IMAGE_VERSION_TAG))
	$(call log_image_revision,pyeddl,${PYEDDL_IMAGE_VERSION_TAG},install,PYEDDL)

build_pyecvl: build_pyecvl_toolkit _build_pyecvl_base ## Build 'pyecvl' image
	$(call build_image,pylibs,pyecvl,${PYECVL_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION) \
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
		--label PYEDDL_REVISION=${PYEDDL_REVISION},pyeddl:$(PYLIBS_BASE_IMAGE_VERSION_TAG),pyecvl-toolkit:$(PYECVL_IMAGE_VERSION_TAG))
	$(call log_image_revision,pyecvl,${PYECVL_IMAGE_VERSION_TAG},install,PYECVL)

build_pylibs: build_pyecvl ## Build 'pylibs' image
	$(call build_image,pylibs,pylibs,${DOCKER_LIBS_IMAGE_VERSION_TAG},\
		--label CONTAINER_VERSION=$(CONTAINER_VERSION) \
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
		--label PYEDDL_REVISION=${PYEDDL_REVISION},pyecvl:$(PYECVL_IMAGE_VERSION_TAG),,${DOCKER_LIBS_EXTRA_TAGS})


############################################################################################################################
### Tests
############################################################################################################################
define check_image
	printf "\nSearching image $(1)... " ; \
	images=$(docker images -q ${1}) 2> /dev/null ; \
	if [ -z "$${images}" ]; then \
		[ "${_DO_NOT_PULL_DOCKER_IMAGES}" == "0" ] && docker pull ${DOCKER_REPOSITORY_OWNER}/${1} 2> /dev/null ; \
		docker tag ${DOCKER_REPOSITORY_OWNER}/${1} ${1} 2> /dev/null ; \
	fi ; \
	printf "\n"
endef

define test_image
	$(eval image := $(1))
	$(eval test_script := $(2))
	$(eval container_paths := $(3))
	$(eval rname := $(shell cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1))
	echo -e "\n\n\n*************************************************************************************************************" >&2 ; \
	echo -e "*** Test: '${test_script}' @ '${image}' image ***" >&2 ; \
	echo -e "*************************************************************************************************************\n" >&2 ; \
	cnames="" ; \
	for cpath in ${container_paths}; do \
	xcpath=($$(echo $${cpath} | tr "=" " ")) ; \
	cname=$$(echo $${xcpath[0]} | sed -e +s+:.*++)-${rname} ; \
	cnames="$${cnames} $${cname}" ; \
	volumes="$${volumes} --volumes-from $${cname}" ; \
	printf "\nCreating temp container instance of '$${xcpath[0]}' (name: $${cname})... " >&2; \
	$(call check_image,$${xcpath[0]}) ; \
	docker create --name $${cname} -v "$${xcpath[1]}" $${xcpath[0]} > /dev/null ; \
	printf "DONE\n" >&2 ; \
	done ; \
	printf "\n\n" ; \
	$(call check_image,${image}) ; \
	cat ${test_script} | ${DOCKER_RUN} -e GPU_RUNTIME="${GPU_RUNTIME}" $${volumes} ${image} /bin/bash ; \
	exit_code=$$? ; \
	for cname in $${cnames}; do \
	printf "\nRemoving temp container instance '$${cname}'... " >&2; \
	docker rm -f $${cname} > /dev/null ; printf "DONE" >&2 ; done ; \
	echo -e "\n*************************************************************************************************************\n\n\n" >&2 ; \
	exit $${exit_code}
endef

test: _test ## Test all docker images

_test: \
	test_eddl test_eddl_toolkit \
	test_ecvl test_ecvl_toolkit \
	test_pyeddl test_pyeddl_toolkit \
	test_pyecvl test_pyecvl_toolkit

test_eddl: eddl_folder ## Test 'eddl' images
	$(eval EDDL_IMAGE_VERSION_TAG := $(or ${EDDL_IMAGE_VERSION_TAG},${EDDL_REVISION}))
	@$(call test_image,\
		eddl:${EDDL_IMAGE_VERSION_TAG},\
		tests/test_eddl.sh,\
		eddl-toolkit:${EDDL_IMAGE_VERSION_TAG}=/usr/local/src/eddl \
	)
	
test_eddl_toolkit: eddl_folder ## Test 'eddl' images
	$(eval EDDL_IMAGE_VERSION_TAG := $(or ${EDDL_IMAGE_VERSION_TAG},${EDDL_REVISION}))
	@$(call test_image,eddl-toolkit:${EDDL_IMAGE_VERSION_TAG},tests/test_eddl.sh)

test_ecvl: ecvl_folder ## Test 'ecvl' images
	$(eval ECVL_IMAGE_VERSION_TAG := $(or ${ECVL_IMAGE_VERSION_TAG},${ECVL_REVISION}))
	@$(call test_image,\
		ecvl:${ECVL_IMAGE_VERSION_TAG},\
		tests/test_ecvl.sh,\
		ecvl-toolkit:${ECVL_IMAGE_VERSION_TAG}=/usr/local/src/ecvl \
	)

test_ecvl_toolkit: ecvl_folder ## Test 'ecvl' images
	$(eval ECVL_IMAGE_VERSION_TAG := $(or ${ECVL_IMAGE_VERSION_TAG},${ECVL_REVISION}))
	@$(call test_image,ecvl-toolkit:${ECVL_IMAGE_VERSION_TAG},tests/test_ecvl.sh)

test_pyeddl: pyeddl_folder ## Test 'ecvl' images
	$(eval PYEDDL_IMAGE_VERSION_TAG := $(or ${PYEDDL_IMAGE_VERSION_TAG},${PYEDDL_REVISION}))
	@$(call test_image,\
		pyeddl:${PYEDDL_IMAGE_VERSION_TAG},\
		tests/test_pyeddl.sh,\
		pyeddl-toolkit:${PYEDDL_IMAGE_VERSION_TAG}=/usr/local/src/pyeddl\
	)

test_pyeddl_toolkit: pyeddl_folder ## Test 'ecvl' images
	$(eval PYEDDL_IMAGE_VERSION_TAG := $(or ${PYEDDL_IMAGE_VERSION_TAG},${PYEDDL_REVISION}))
	@$(call test_image,pyeddl-toolkit:${PYEDDL_IMAGE_VERSION_TAG},tests/test_pyeddl.sh)

test_pyecvl: pyecvl_folder ## Test 'ecvl' images
	$(eval ECVL_IMAGE_VERSION_TAG := $(or ${ECVL_IMAGE_VERSION_TAG},${ECVL_REVISION}))
	$(eval PYECVL_IMAGE_VERSION_TAG := $(or ${PYECVL_IMAGE_VERSION_TAG},${PYECVL_REVISION}))
	@$(call test_image,\
		pyecvl:${PYECVL_IMAGE_VERSION_TAG},\
		tests/test_pyecvl.sh,\
		'ecvl-toolkit:${ECVL_IMAGE_VERSION_TAG}=/usr/local/src/ecvl' \
		'pyecvl-toolkit:${PYECVL_IMAGE_VERSION_TAG}=/usr/local/src/pyecvl' \
	)

test_pyecvl_toolkit: #pyecvl_folder ## Test 'ecvl' images
	$(eval PYECVL_IMAGE_VERSION_TAG := $(or ${PYECVL_IMAGE_VERSION_TAG},${PYECVL_REVISION}))
	@@$(call test_image,pyecvl-toolkit:${PYECVL_IMAGE_VERSION_TAG},tests/test_pyecvl.sh)

############################################################################################################################
### Push Docker images
############################################################################################################################
push: _push ## Push all images

_push: \
	push_libs_base push_libs_base_toolkit \
	push_libs push_libs_toolkit\
	push_eddl push_eddl_toolkit \
	push_ecvl push_ecvl_toolkit \
	push_pylibs push_pylibs_toolkit \
	push_pyeddl push_pyeddl_toolkit \
	push_pyecvl push_pyecvl_toolkit

push_libs: docker_login ## Push 'libs' image
	$(call push_image,libs,${DOCKER_LIBS_IMAGE_VERSION_TAG},${DOCKER_LIBS_EXTRA_TAGS})

push_libs_base: docker_login ## Push 'lib-base' image
	$(call push_image,libs-base,${DOCKER_BASE_IMAGE_VERSION_TAG})

push_eddl: docker_login eddl_folder ## Push 'eddl' image
	$(call push_image,eddl,${EDDL_IMAGE_VERSION_TAG},${EDDL_REVISION} ${EDDL_TAG})

push_ecvl: docker_login ecvl_folder ## Push 'ecvl' image
	$(call push_image,ecvl,${ECVL_IMAGE_VERSION_TAG},${ECVL_REVISION} ${ECVL_TAG})

push_libs_toolkit: docker_login ## Push 'libs-toolkit' image
	$(call push_image,libs-toolkit,${DOCKER_LIBS_IMAGE_VERSION_TAG},${DOCKER_LIBS_EXTRA_TAGS})

push_libs_base_toolkit: docker_login ## Push 'libs-base-toolkit' image
	$(call push_image,libs-base-toolkit,${DOCKER_BASE_IMAGE_VERSION_TAG})

push_eddl_toolkit: docker_login eddl_folder ## Push 'eddl-toolkit' images
	$(call push_image,eddl-toolkit,${EDDL_IMAGE_VERSION_TAG},${EDDL_REVISION} ${EDDL_TAG})

push_ecvl_toolkit: docker_login ecvl_folder ## Push 'ecvl-toolkit' images
	$(call push_image,ecvl-toolkit,${ECVL_IMAGE_VERSION_TAG},${ECVL_REVISION} ${ECVL_TAG})

push_pylibs: docker_login ## Push 'pylibs' images
	$(call push_image,pylibs,${DOCKER_LIBS_IMAGE_VERSION_TAG},${DOCKER_LIBS_EXTRA_TAGS})

push_pyeddl: docker_login pyeddl_folder ## Push 'pyeddl' images
	$(call push_image,pyeddl,${PYEDDL_IMAGE_VERSION_TAG},${PYEDDL_REVISION} ${PYEDDL_TAG})

push_pyecvl: docker_login pyecvl_folder ## Push 'pyecvl' images
	$(call push_image,pyecvl,${PYECVL_IMAGE_VERSION_TAG},${PYECVL_REVISION} ${PYECVL_TAG})

push_pylibs_toolkit: docker_login ## Push 'pylibs-toolkit' images
	$(call push_image,pylibs-toolkit,${DOCKER_LIBS_IMAGE_VERSION_TAG},${DOCKER_LIBS_EXTRA_TAGS})

push_pyeddl_toolkit: docker_login pyeddl_folder ## Push 'pyeddl-toolkit' images
	$(call push_image,pyeddl-toolkit,${PYEDDL_IMAGE_VERSION_TAG},${PYEDDL_REVISION} ${PYEDDL_TAG})

push_pyecvl_toolkit: docker_login pyecvl_folder ## Push 'pyeddl-toolkit' images
	$(call push_image,pyecvl-toolkit,${PYECVL_IMAGE_VERSION_TAG},${PYECVL_REVISION} ${PYECVL_TAG})

############################################################################################################################
### Piblish Docker images
############################################################################################################################
publish: build push ## Publish all images to a Docker Registry (e.g., DockerHub)

publish_libs: build_libs push_libs ## Publish 'libs' image

publish_eddl: build_eddl push_eddl ## Publish 'eddl' image

publish_ecvl: build_ecvl push_ecvl ## Publish 'ecvl' image

publish_libs_toolkit: build_libs_toolkit push_libs_toolkit ## Publish 'libs-toolkit' image

publish_eddl_toolkit: build_eddl_toolkit push_eddl_toolkit ## Publish 'eddl-toolkit' image

publish_ecvl_toolkit: build_ecvl_toolkit push_ecvl_toolkit ## Publish 'ecvl-toolkit' image

publish_pylibs: build_pylibs push_pylibs ## Publish 'pylibs' image

publish_pyeddl: build_pyeddl push_pyeddl ## Publish 'pyeddl' image

publish_pyecvl: build_pyecvl push_pyecvl ## Publish 'pyecvl' image

publish_pylibs_toolkit: build_pylibs_toolkit push_pylibs_toolkit ## Publish 'pylibs-toolkit' image

publish_pyeddl_toolkit: build_pyeddl_toolkit push_pyeddl_toolkit ## Publish 'pyeddl-toolkit' image

publish_pyecvl_toolkit: build_pyecvl_toolkit push_pyecvl_toolkit ## Publish 'pyecvl-toolkit' image

# login to the Docker HUB repository
_docker_login: 
	@if [[ ${DOCKER_LOGIN_DONE} == false ]]; then \
		echo "Logging into Docker registry ${DOCKER_REGISTRY}..." ; \
		echo ${DOCKER_PASSWORD} | docker login ${DOCKER_REGISTRY} --username ${DOCKER_USER} --password-stdin \
	else \
		echo "Logging into Docker registry already done" ; \
	fi

docker-login: _docker-login ## Login to the Docker Registry
	$(eval DOCKER_LOGIN_DONE := true)


############################################################################################################################
### Clean sources
############################################################################################################################
clean_eddl_sources: ## clean repository containing EDDL source code
	$(call clean_sources,libs/eddl)

clean_ecvl_sources: ## clean repository containing ECVL source code
	$(call clean_sources,libs/ecvl)

clean_pyeddl_sources: ## clean repository containing PyEDDL source code
	$(call clean_sources,pylibs/pyeddl)

clean_pyecvl_sources: ## clean repository containing PyECVL source code
	$(call clean_sources,pylibs/pyecvl)

clean_libs_sources: clean_eddl_sources clean_ecvl_sources ## clean repository containing libs source code

clean_pylibs_sources: clean_pyeddl_sources clean_pyecvl_sources ## clean repository containing pylibs source code

clean_sources: clean_pylibs_sources clean_libs_sources _clean_libraries_logs ## clean repository containing source code


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

clean_images: \
	clean_pylibs_images clean_libs_images clean_base_images \
	clean_ecvl_images clean_eddl_images \
	clean_pyecvl_images clean_pylibs_images \
	_clean_images_logs

####################################################################

_clean_dependencies_logs:
	$(file >${DEPENDENCIES_LOG},)
	@echo "Logs of dependencies deleted"

_clean_images_logs: _clean_dependencies_logs
	$(file >${IMAGES_LOG},)
	@echo "Logs of images deleted"

_clean_libraries_logs: _clean_dependencies_logs
	$(file >${LIBRARIES_LOG},)
	@echo "Logs of libraries deleted"

clean_logs: _clean_images_logs _clean_libraries_logs ## clean logs


############################################################################################################################
### Clean Sources and Docker images
############################################################################################################################
clean: clean_images clean_sources clean_logs


.PHONY: help \
	clean_logs _clean_dependencies_logs _clean_libraries_logs _clean_images_logs \
	libraries_list images_list dependencies_list dependency_graph \
	libs_folder eddl_folder ecvl_folder pylibs_folder \
	pyeddl_folder _pyeddl_shallow_clone _pyecvl_second_level_dependencies \
	pyecvl_folder _pyeddl_shallow_clone _pyecvl_first_level_dependencies _pyecvl_second_level_dependencies \
	apply_pyeddl_patches apply_pyecvl_patches \
	clean clean_libs clean_pylibs apply_libs_patches \
	build _build \
	_build_libs_base_toolkit \
	build_eddl_toolkit build_ecvl_toolkit build_libs_toolkit \
	_build_libs_base build_eddl build_ecvl build_libs \
	_build_pyeddl_base_toolkit _build_pyecvl_base_toolkit _build_pylibs_base \
	build_pyeddl_toolkit build_pyecvl_toolkit build_pylibs_toolkit\
	_build_pyeddl_base _build_pyecvl_base build_pyeddl build_pyecvl build_pylibs \
	_docker_login docker_login \
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
	tests _tests test_eddl test_eddl_toolkit test_ecvl test_ecvl_toolkit test_pyeddl \
	test_pyeddl_toolkit test_pyecvl test_pyecvl_toolkit \
	clean_sources \
	clean_eddl_sources clean_ecvl_sources \
	clean_pyeddl_sources clean_pyecvl_sources \
	clean \
	clean_images \
	clean_base_images \
	clean_eddl_images clean_ecvl_images clean_libs_images \
	clean_pyeddl_images clean_pyecvl_images clean_pylibs_images
