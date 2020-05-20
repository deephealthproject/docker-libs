#!/bin/bash

#set -x
set -o nounset
set -o errexit
set -o pipefail
# without errtrace functions don't inherit the ERR trap
set -o errtrace

# default libs version
export DOCKER_LIBS_REPO="${DOCKER_LIBS_REPO:-https://github.com/deephealthproject/docker-libs.git}"
export DOCKER_LIBS_BRANCH=${DOCKER_LIBS_BRANCH:-develop}
export DOCKER_LIBS_VERSION=""

# set Docker repository
export DOCKER_REPOSITORY_OWNER="${DOCKER_REPOSITORY_OWNER:-dhealth}"

# env requirements
DOCKER_USER=${DOCKER_USER:-}
DOCKER_PASSWORD=${DOCKER_PASSWORD:-}

GIT_URL=${GIT_URL:-}

# set script version
VERSION=0.3.0

function abspath() {
  local path="${*}"

  if [[ -d "${path}" ]]; then
    echo "$( cd "${path}" >/dev/null && pwd )"
  else
    echo "$( cd "$( dirname "${path}" )" >/dev/null && pwd )/$(basename "${path}")"
  fi
}

function log() {
  echo -e "${@}" >&2
}

function debug_log() {
  if [[ -n "${DEBUG:-}" ]]; then
    echo -e "DEBUG: ${@}" >&2
  fi
}

function error_log() {
  echo -e "ERROR: ${@}" >&2
}

function error_trap() {
  error_log "Error at line ${BASH_LINENO[1]} running the following command:\n\n\t${BASH_COMMAND}\n\n"
  error_log "Stack trace:"
  for (( i=1; i < ${#BASH_SOURCE[@]}; ++i)); do
    error_log "$(printf "%$((4*$i))s %s:%s\n" " " "${BASH_SOURCE[$i]}" "${BASH_LINENO[$i]}")"
  done
  exit 2
}

trap error_trap ERR

function usage_error() {
  if [[ $# > 0 ]]; then
    echo -e "ERROR: ${@}" >&2
  fi
  help
  exit 2
}

function print_version() {
  echo ${VERSION}
}

function help() {
  local script_name=$(basename "$0")
  echo -e "\nUsage of '${script_name}'

  ${script_name} [options]
  ${script_name} -h        prints this help message
  ${script_name} -v        prints the '${script_name}' version

  OPTIONS:
    --target [CPU|GPU]                Set the build target (CPU or GPU; default= GPU)
    --clean-sources                   Remove library sources
    --clean-images                    Remove local Docker images
    --disable-cache                   Disable Docker cache
    --disable-build                   Disable build of Docker images
    --disable-pull                    Disable pull of existing Docker images
    --disable-push                    Disable push of Docker images
    --disable-tests                   Disable tests of Docker images
    --disable-docker-login            Disable login on Docker registry
    --debug                           Enable debug logs

  ENVIRONMENT requirements:
    * DOCKER_USER
    * DOCKER_PASSWORD

  ENVIRONMENT defaults:
    * DOCKER_LIBS_REPO                => https://github.com/deephealthproject/docker-libs.git
    * DOCKER_LIBS_BRANCH              => develop
    * DOCKER_REPOSITORY_OWNER         => dhealth
  " >&2
}

# sw version
LIBS_TAG=$(git tag -l --points-at HEAD | tail -n 1)
LIBS_REVISION=$(git rev-parse --short HEAD | sed -E 's/-//; s/ .*//')
LIBS_BRANCH=$(git rev-parse --abbrev-ref HEAD | sed -E 's+(remotes/|origin/)++g; s+/+-+g; s/ .*//')
LIBS_VERSION=$(if [[ -n "${LIBS_TAG}" ]]; then echo ${LIBS_TAG}; else echo ${LIBS_BRANCH}-${LIBS_REVISION}; fi)

# various settings
CLEAN_IMAGES=0
CLEAN_SOURCES=0
DISABLE_CACHE=0
DISABLE_PULL=0
DISABLE_BUILD=0
DISABLE_PUSH=0
DISABLE_TESTS=0
DISABLE_DOCKER_LOGIN=0
BUILD_TARGET=GPU

# get docker-libs repository
function clone_docker_libs() {
    if [[ ! -d "docker-libs" ]]; then
      log "Cloning docker-libs (branch=${DOCKER_LIBS_BRANCH}, rev=${DOCKER_LIBS_VERSION})..."
      if [[ -n "${DOCKER_LIBS_BRANCH}" ]]; then
        branch="-b ${DOCKER_LIBS_BRANCH}"
      fi
      git clone ${branch} ${DOCKER_LIBS_REPO}
    fi
    if [[ -n "${DOCKER_LIBS_VERSION}" ]]; then
      log "Cloning docker-libs (rev.${DOCKER_LIBS_VERSION})..."
      cd docker-libs && git fetch && git reset --hard ${DOCKER_LIBS_VERSION}
    fi
    log "DONE"
}

# Docker login
function docker_login() {
    echo ${DOCKER_PASSWORD} | docker login --username ${DOCKER_USER} --password-stdin
    export DOCKER_LOGIN_DONE="true"
}

function run() {
  local REPOSITORY=""
  local LIB_NAME=""
  # set repository
  if [[ -n "${GIT_URL}" ]]; then \
    REPOSITORY=$(echo "${GIT_URL}" | sed -E 's+(.*)/([^/]*)\.git+\2+') ; \
  else
    REPOSITORY=$(basename $(git rev-parse --show-toplevel)) ;
  fi
  # set library name
  LIB_NAME=$(echo "${REPOSITORY}" | tr a-z A-Z | sed 's+DOCKER-LIBS+LIBS+; s+-+_+')

  # set git tag & branch & image prefix
  # and define whether to push lates tag
  GIT_BRANCH=${GIT_BRANCH:-$(git rev-parse --abbrev-ref HEAD | sed -E 's+(remotes/|origin/|tags/)++g; s+/+-+g; s/ .*//')}
  BRANCH_NAME=$(echo "${GIT_BRANCH}" | sed 's+origin/++g; s+refs/tags/++g')
  NORMALIZED_BRANCH_NAME=$(echo "${BRANCH_NAME}" | sed 's+/+-+g; s+[[:space:]]++g')
  TAG=$(git tag -l --points-at HEAD | tail -n 1 | sed 's+[[:space:]]++g')
  REVISION="$(git rev-parse --short HEAD --short | sed 's+[[:space:]]++g')"
  if [ -n "${TAG}" ]; then
    DOCKER_IMAGE_PREFIX="${TAG}"
    # update latest if a tag exists and the branch is master
    if [ "${BRANCH_NAME}" == "master" ]; then
      export DOCKER_IMAGE_LATEST=true
    fi
  else
    DOCKER_IMAGE_PREFIX="${REVISION}"
  fi

  # define Docker image tags
  export BUILD_NUMBER=${BUILD_NUMBER:-$(date '+%Y%m%d%H%M%S')}
  #export DOCKER_IMAGE_TAG_EXTRA="${DOCKER_IMAGE_PREFIX}_build${BUILD_NUMBER}"
  #export DOCKER_IMAGE_TAG_EXTRA="${DOCKER_IMAGE_TAG_EXTRA} ${NORMALIZED_BRANCH_NAME}_build${BUILD_NUMBER}"

  # set branch and revision
  export ${LIB_NAME}_BRANCH=${BRANCH_NAME}
  export ${LIB_NAME}_REVISION=${REVISION}

  # log environment
  printenv

  # detect repository 
  lib_suffix=""
  if [[ "${LIB_NAME}" != "LIBS" ]]; then
    lib_suffix="_${REPOSITORY}"
    export CONFIG_FILE=""
    clone_docker_libs
    cd docker-libs
  fi

  # cleanup sources
  if [[ "${CLEAN_SOURCES}" == "true" ]]; then
    make clean_sources
  fi

  # cleanup images
  if [[ "${CLEAN_IMAGES}" == "true" ]]; then
    make clean_images
  fi

  # build images
  if [[ ${DISABLE_BUILD} == 0 ]]; then
    log "Docker images before..."
    docker images
    make build${lib_suffix} ;
    log "Docker images after..."
    docker images
  fi

  # make tests
  if [[ ${DISABLE_TESTS} == 0 ]]; then 
    if [[ -n ${lib_suffix} ]]; then
      #make test${lib_suffix} ;
      make test${lib_suffix}_toolkit ;
    else
      make test ;
    fi
  fi

  # push images
  if [[ ${DISABLE_PUSH} == 0 ]]; then
    # login to DockerHub
    if [[ ${DISABLE_DOCKER_LOGIN} == 0 ]]; then
      if [[ -z ${DOCKER_USER} || -z ${DOCKER_PASSWORD} ]]; then
        usage_error "You need to set DOCKER_USER and DOCKER_PASSWORD on your environment"
      fi
      docker_login
      export DOCKER_LOGIN_DONE="true"
    fi
    if [[ -n ${lib_suffix} ]]; then
      #make push${lib_suffix} ;
      make push${lib_suffix}_toolkit ;
    else
      make push ;
    fi
  fi

  # print images
  if [[ ${DISABLE_BUILD} == 0 ]]; then
    log "\n\nList of Docker images..."
    log "*************************************************************************************************************"
    make images_list

    # print libraries
    log "\n\nList of Libraries..."
    log "*************************************************************************************************************"
    make libraries_list
  fi
}

# parse arguments
POSITIONAL=()
while [[ $# -gt 0 ]]
do
    opt="${1}"
    value="${2:-}"
    case $opt in

        -h) help; exit 0 ;;
        -v) print_version; exit 0 ;;

        --debug)
          DEBUG=true
          shift ;;

        --clean-sources)
          CLEAN_SOURCES=true
          shift ;;

        --clean-images)
          CLEAN_IMAGES=true
          shift ;;

        --disable-cache)
          DISABLE_CACHE=1
          shift ;;

        --disable-build)
          DISABLE_BUILD=1
          shift ;;

        --disable-pull)
          DISABLE_PULL=1
          shift ;;

        --disable-push)
          DISABLE_PUSH=1
          shift ;;

        --disable-tests)
          DISABLE_TESTS=1
          shift ;;

        --disable-docker-login)
          DISABLE_DOCKER_LOGIN=1
          shift ;;

        --target)
          if [[ "CPU GPU" =~ (^|[[:space:]])${2}($|[[:space:]]) ]]; then
            BUILD_TARGET=$2 ;
          else
            usage_error "The target '$2' is not a valid target"
          fi
          shift 2 ;;

        *) # unknown option
          POSITIONAL+=("$opt") # save it in an array for later
          shift ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

# get the absolute path of CONFIG_DIR
CONFIG_DIR=$(abspath $(pwd))

debug_log "docker-libs branch: ${DOCKER_LIBS_BRANCH}"
debug_log "docker-libs revision: ${DOCKER_LIBS_VERSION}"
debug_log "disable cache: ${DISABLE_CACHE}"
debug_log "disable pull: ${DISABLE_PULL}"
debug_log "build target: ${BUILD_TARGET}"

#
export DOCKER_LIBS_BRANCH
export DOCKER_LIBS_VERSION
export CLEAN_IMAGES
export CLEAN_SOURCES
export DISABLE_CACHE
export DISABLE_PULL
export BUILD_TARGET

# exec
run
