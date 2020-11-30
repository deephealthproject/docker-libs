#!/bin/bash

# exit on error
set -e

# set the path containing sources and tests
EDDL_SRC=${EDDL_SRC:-"/usr/local/src/eddl"}

# ### some unit tests fail on Jenkins, due to memory allocation problems or
# ### tight numerical comparisons. See, e.g., https://jenkins-master-deephealth-unix01.ing.unimore.it/job/DeepHealth-Docker/job/libs/133/consoleFull

# cd ${EDDL_SRC}/build && bin/unit_tests
cd ${EDDL_SRC}/build && bin/mnist_auto_encoder
