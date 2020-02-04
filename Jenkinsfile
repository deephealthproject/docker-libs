pipeline {
  agent {
    node { label 'docker && linux && !gpu' }
  }
  triggers{
    upstream(
      upstreamProjects: 'DeepHealth/eddl/master,DeepHealth/ecvl/master,DeepHealth/pyeddl/master,DeepHealth/pyecvl/master',
      threshold: hudson.model.Result.SUCCESS)
  }
  environment {
    BASE_SRC = "/usr/local/src"
    ECVL_SRC = "${BASE_SRC}/ecvl"
    EDDL_SRC = "${BASE_SRC}/eddl"
    PYECVL_SRC = "${BASE_SRC}/pyecvl"
    PYEDDL_SRC = "${BASE_SRC}/pyeddl"
    // ECVL Settings
    ECVL_REPOSITORY = "https://github.com/deephealthproject/ecvl.git"
    ECVL_BRANCH = "master"
    ECVL_REVISION = sh(returnStdout: true, script: "git ls-remote ${ECVL_REPOSITORY} ${ECVL_BRANCH} | awk '{print \$1}'").trim()
    // PyECVL Settings
    PYECVL_REPOSITORY = "https://github.com/deephealthproject/pyecvl.git"
    PYECVL_BRANCH = "master"
    PYECVL_REVISION = sh(returnStdout: true, script: "git ls-remote ${PYECVL_REPOSITORY} ${PYECVL_BRANCH} | awk '{print \$1}'").trim()
    // EDDL Settings    
    EDDL_REPOSITORY = "https://github.com/deephealthproject/eddl.git"
    EDDL_BRANCH = "master"
    EDDL_REVISION = sh(returnStdout: true, script: "git ls-remote ${EDDL_REPOSITORY} ${EDDL_BRANCH} | awk '{print \$1}'").trim()
    // PyEDDL Settings
    PYEDDL_REPOSITORY = "https://github.com/deephealthproject/pyeddl.git"
    PYEDDL_BRANCH = "master"
    PYEDDL_REVISION = sh(returnStdout: true, script: "git ls-remote ${PYEDDL_REPOSITORY} ${PYEDDL_BRANCH} | awk '{print \$1}'").trim()
    // Extract additional info
    NORMALIZED_BRANCH_NAME = sh(returnStdout: true, script: "echo ${BRANCH_NAME} | sed 's+/+-+g'").trim()
    REPO_TAG = sh(returnStdout: true, script: "tag=\$(git tag -l --points-at HEAD); if [[ -n \${tag} ]]; then echo \${tag}; else git rev-parse --short HEAD --short; fi").trim()
    // Docker Settings
    DOCKER_IMAGE_LATEST = sh(returnStdout: true, script: "if [ '${GIT_BRANCH}' = 'master' ]; then echo 'true'; else echo 'false'; fi").trim()
    DOCKER_IMAGE_TAG = "${NORMALIZED_BRANCH_NAME}_build${BUILD_NUMBER}"
    DOCKER_IMAGE_TAG_EXTRA = "${REPO_TAG} ${REPO_TAG}_build${BUILD_NUMBER}"
    DOCKER_REPOSITORY_OWNER = "dhealth"
    // Docker credentials
    registryCredential = 'dockerhub-deephealthproject'
    // Skip DockerHub
    DOCKER_LOGIN_DONE = true
  }
  stages {

    stage('Configure') {
      steps {
        sh 'git fetch --tags'
        sh 'printenv'
      }
    }

    stage('Build') {

      parallel {

        stage('Master Build') {
          when {
            allOf {
              branch 'master' ;
              not { triggeredBy 'UpstreamCause' }
            }
          }
          steps {
            script {
              sh 'make build'
              docker.withRegistry( '', registryCredential ) {
                sh 'CONFIG_FILE="" DOCKER_IMAGE_TAG_EXTRA="" make push_libs_toolkit'
                sh 'CONFIG_FILE="" DOCKER_IMAGE_TAG_EXTRA="" make push_pylibs_toolkit'
              }
            }
          }
        }

        stage('Development Build') {
          when {
            allOf {
              not { branch "master" } ;
              triggeredBy 'UpstreamCause'
            }
          }
          steps {
            script {
              sh 'CONFIG_FILE="" make build'
              docker.withRegistry( '', registryCredential ) {
                  sh 'CONFIG_FILE="" DOCKER_IMAGE_TAG_EXTRA="" make push_libs_toolkit'
                  sh 'CONFIG_FILE="" DOCKER_IMAGE_TAG_EXTRA="" make push_pylibs_toolkit'
              }
            }
          }
        }
      }
    }

    stage('Test') {

      parallel {

        stage('Test EDDL') {
          agent {
            docker { image '${DOCKER_REPOSITORY_OWNER}/libs-toolkit:${DOCKER_IMAGE_TAG}' }
          }
          steps {
            sh 'cd ${EDDL_SRC}/build && ctest -C Debug -VV'
          }
        }

        stage('Test ECVL') {
          agent {
            docker { image '${DOCKER_REPOSITORY_OWNER}/libs-toolkit:${DOCKER_IMAGE_TAG}' }
          }
          steps {
            sh 'cd ${ECVL_SRC}/build && ctest -C Debug -VV'
          }
        }

        stage('Test PyEDDL') {
          agent {
            docker { image '${DOCKER_REPOSITORY_OWNER}/pylibs-toolkit:${DOCKER_IMAGE_TAG}' }
          }
          steps {
            sh 'cd ${PYEDDL_SRC} && pytest tests'
            sh 'cd ${PYEDDL_SRC}/examples && python3 Tensor/eddl_tensor.py'
            sh 'cd ${PYEDDL_SRC}/examples && python3 NN/other/eddl_ae.py --epochs 1'
          }
        }

        stage('Test PyECVL') {
          agent {
            docker { image '${DOCKER_REPOSITORY_OWNER}/pylibs-toolkit:${DOCKER_IMAGE_TAG}' }
          }
          steps {
            sh 'cd ${PYECVL_SRC} && pytest tests'
            sh 'cd ${PYECVL_SRC}/examples && python3 dataset.py "${ECVL_SRC}/examples/data/mnist/mnist.yml"'
            sh 'cd ${PYECVL_SRC}/examples && python3 ecvl_eddl.py "${ECVL_SRC}/examples/data/test.jpg" "${ECVL_SRC}/examples/data/mnist/mnist.yml"'
            sh 'cd ${PYECVL_SRC}/examples && python3 img_format.py "${ECVL_SRC}/examples/data/nifti/LR_nifti.nii" "${ECVL_SRC}/data/isic_dicom/ISIC_0000008.dcm"'
            sh 'cd ${PYECVL_SRC}/examples && python3 imgproc.py "${ECVL_SRC}/examples/data/test.jpg"'
            sh 'cd ${PYECVL_SRC}/examples && python3 openslide.py "${ECVL_SRC}/examples/data/hamamatsu/test3-DAPI 2 (387).ndpi"'
            sh 'cd ${PYECVL_SRC}/examples && python3 read_write.py "${ECVL_SRC}/examples/data/test.jpg test_mod.jpg"'
          }
        }
      }
    }

    stage('Publish') {

      parallel {

        stage('Publish Master Build') {
          when {
            allOf {
              branch 'master';
              not { triggeredBy 'UpstreamCause' }
            }
          }
          steps {
            script {
              docker.withRegistry( '', registryCredential ) {
                sh '''
                  tag=$(git tag -l --points-at HEAD);
                  if [ -n "${tag}" ]; then
                    REPO_TAG="${tag}"
                  else
                    REPO_TAG=$(git rev-parse --short HEAD --short)
                  fi
                  DOCKER_IMAGE_TAG_EXTRA="${DOCKER_IMAGE_TAG_EXTRA} ${REPO_TAG} ${REPO_TAG}_build${BUILD_NUMBER}"
                  echo "Pushing tags: ${DOCKER_IMAGE_TAG_EXTRA}"
                  make push
                '''
              }
            }
          }
        }

        stage('Publish Development Build') {
          when {
            allOf {
              not { branch "master" };
              triggeredBy 'UpstreamCause'
            }
          }
          steps {
            script {
              docker.withRegistry( '', registryCredential ) {
                sh '''
                  tag=$(git tag -l --points-at HEAD);
                  if [ -n "${tag}" ]; then 
                    REPO_TAG="${tag}"
                  else 
                    REPO_TAG=$(git rev-parse --short HEAD --short)
                  fi
                  DOCKER_IMAGE_TAG_EXTRA="${DOCKER_IMAGE_TAG_EXTRA} ${REPO_TAG} ${REPO_TAG}_build${BUILD_NUMBER}"
                  echo "Pushing tags: ${DOCKER_IMAGE_TAG_EXTRA}"
                  CONFIG_FILE="" make push
                '''
              }
            }
          }
        }
      }
    }
  }

  post {
    always {
      echo 'One way or another, I have finished'
    }
    success {
      echo "Docker images successfully build and published with tags: ${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE_TAG_EXTRA}"
      echo "Library revisions..."
      echo "* ECVL revision: ${ECVL_REVISION}"
      echo "* EDDL revision: ${EDDL_REVISION}"
      echo "* PyECVL revision: ${PYECVL_REVISION}"
      echo "* PyEDDL revision: ${PYEDDL_REVISION}"
    }
    unstable {
      echo 'I am unstable :/'
    }
    failure {
      echo 'I failed :('
    }
    cleanup {      
      // sh 'make clean'
      deleteDir() /* clean up our workspace */
      sh 'docker images'
      sh 'docker image prune -f'
      sh 'if [ "$(docker images | grep -E \"(l|pyl)ibs([[:space:]]|-toolkit)\")" ]; then docker images | grep -E "(l|pyl)ibs([[:space:]]|-toolkit)" | awk \'{print $3}\' | uniq | xargs docker rmi -f; fi;'
    }
  } 
}