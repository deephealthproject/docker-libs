#!/bin/bash

#set -x
set -o nounset
set -o errexit
set -o pipefail
# without errtrace functions don't inherit the ERR trap
set -o errtrace


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

function help() {
  local script_name=$(basename "$0")
  echo -e "\nUsage of '${script_name}'
  ${script_name} [options]
  ${script_name} -h        prints this help message
  ${script_name} -v        prints the '${script_name}' version
  OPTIONS:
    --clean-sources                   Remove library sources
    --clean-images                    Remove local Docker images
    --disable cache                   Disable Docker cache
    --disable pull                    Disable pull of existing Docker images
    --docker-libs-revision <REV>   
    --docker-libs-branch <BRANCH>
  " >&2
}

# sw version
LIBS_TAG=$(git tag -l --points-at HEAD | tail -n 1)
LIBS_REVISION=$(git rev-parse --short HEAD | sed -E 's/-//; s/ .*//')
LIBS_BRANCH=$(git name-rev --name-only HEAD | sed -E 's+(remotes/|origin/)++g; s+/+-+g; s/ .*//')
LIBS_VERSION=$(if [[ -n "${LIBS_TAG}" ]]; then echo ${LIBS_TAG}; else echo ${LIBS_BRANCH}-${LIBS_REVISION}; fi)

# set base images
export DOCKER_NVIDIA_DEVELOP_IMAGE="nvidia/cuda:10.1-devel"
export DOCKER_NVIDIA_RUNTIME_IMAGE="nvidia/cuda:10.1-runtime"
export DOCKER_BASE_IMAGE_VERSION_TAG=0.2.0
# set Docker repository
export DOCKER_REPOSITORY_OWNER=dhealth

# default libs version
export DEFAULT_DOCKER_LIBS_BRANCH="develop"
export DOCKER_LIBS_BRANCH=${DEFAULT_DOCKER_LIBS_BRANCH}
export DOCKER_LIBS_VERSION=""

# set Docker repository
export DOCKER_REPOSITORY_OWNER="${DOCKER_REPOSITORY_OWNER:-dhealth}"

# various settings
CLEAN_IMAGES=0
CLEAN_SOURCES=0
DISABLE_CACHE=0
DISABLE_PULL=0


# get docker-libs repository
function clone_docker_libs() {
    if [[ ! -d "docker-libs" ]]; then
      log "Cloning docker-libs (branch=${DOCKER_LIBS_BRANCH}, rev=${DOCKER_LIBS_VERSION})..."
      if [[ -n "${DOCKER_LIBS_BRANCH}" ]]; then
        branch="-b ${DOCKER_LIBS_BRANCH}"
      fi
      echo "git clone "${branch}" https://github.com/kikkomep/docker-libs.git"
      git clone ${branch} https://github.com/kikkomep/docker-libs.git
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
  # set repository
  local REPOSITORY=$(basename $(git rev-parse --show-toplevel))
  # set library name
  local LIB_NAME=$(echo "${REPOSITORY}" | tr a-z A-Z | sed 's+DOCKER-IMAGES+LIBS+')
  # set git tag & branch & image prefix
  # and define whether to push lates tag
  GIT_BRANCH=${GIT_BRANCH:-$(git name-rev --name-only HEAD | sed -E 's+(remotes/|origin/|tags/)++g; s+/+-+g; s/ .*//')}
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
  export DOCKER_IMAGE_TAG="${DOCKER_IMAGE_PREFIX}_build${BUILD_NUMBER}"
  export DOCKER_IMAGE_TAG_EXTRA="${DOCKER_IMAGE_PREFIX} ${NORMALIZED_BRANCH_NAME}_build${BUILD_NUMBER}"

  # set revision
  export ${LIB_NAME}_REVISION=${REVISION}
  # set branch
  export ${LIB_NAME}_BRANCH=${BRANCH_NAME}
  # set image build tag
  export ${LIB_NAME}_IMAGE_VERSION_TAG=${DOCKER_IMAGE_TAG}

  # log environment
  printenv

  echo "${REPOSITORY}"
  

  # detect repository 
  lib_suffix=""
  if [[ "${REPOSITORY}" == "LIBS" ]]; then
    
    echo "SUFF: ${lib_suffix}"    
  else # clone docker-libs
    lib_suffix="_${REPOSITORY}"    
    echo "SUFF ---: ${lib_suffix}"
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
  make build${lib_suffix}
  echo "Docker images after..."
  docker images
  # make tests
  make test${lib_suffix}
  # push images
  #make push${lib_suffix}
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

        --clean-sources)
          CLEAN_SOURCES=true
          shift ;;

        --clean-images)
          CLEAN_IMAGES=true
          shift ;;

        --docker-libs-branch)
          DOCKER_LIBS_BRANCH="${value}"
          shift 2 ;;
        
        --docker-libs-version)
          DOCKER_LIBS_VERSION="${value}"
          shift 2 ;;

        --disable-cache)
          DISABLE_CACHE=1
          shift ;;

        --disable-pull)
          DISABLE_PULL=1
          shift ;;

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

#
export DOCKER_LIBS_BRANCH
export DOCKER_LIBS_VERSION
export CLEAN_IMAGES
export CLEAN_SOURCES
export DISABLE_CACHE
export DISABLE_PULL

# login to DockerHub
#docker_login

# exec
run
