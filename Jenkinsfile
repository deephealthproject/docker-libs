
// ECVL Settings
ECVL_REPOSITORY = "https://github.com/deephealthproject/ecvl.git"
ECVL_BRANCH = "master"
ECVL_REVISION = ""
ECVL_IMAGE_VERSION_TAG = ""
// PyECVL Settings
PYECVL_REPOSITORY = "https://github.com/deephealthproject/pyecvl.git"
PYECVL_BRANCH = "master"
PYECVL_REVISION = ""
PYECVL_IMAGE_VERSION_TAG = ""
// EDDL Settings    
EDDL_REPOSITORY = "https://github.com/deephealthproject/eddl.git"
EDDL_BRANCH = "master"
EDDL_REVISION = ""
EDDL_IMAGE_VERSION_TAG = ""
// PyEDDL Settings
PYEDDL_REPOSITORY = "https://github.com/deephealthproject/pyeddl.git"
PYEDDL_BRANCH = "master"
PYEDDL_REVISION = ""
PYEDDL_IMAGE_VERSION_TAG = ""
// Extract additional info
REPO_TAG = ""
NORMALIZED_BRANCH_NAME = ""
// Docker Settings
DOCKER_IMAGE_LATEST = ""
DOCKER_IMAGE_TAG = ""
DOCKER_IMAGE_TAG_EXTRA = ""
DOCKER_REPOSITORY_OWNER = "dhealth"
DOCKER_BASE_IMAGE_VERSION_TAG = "0.1.8"
// Upstream project data
UPSTREAM_GIT_REPO = ""
UPSTREAM_GIT_BRANCH = ""
UPSTREAM_GIT_REVISION = ""
UPSTREAM_PROJECT_DATA = ""

////////////////////////////////////////////////////////////////////////////////////////////
// Pipeline Definition
////////////////////////////////////////////////////////////////////////////////////////////
pipeline {
  agent {
    node { label 'docker && linux && !gpu' }
  }
  triggers{
    upstream(
      upstreamProjects: 'DeepHealth/eddl,DeepHealth/ecvl/master,DeepHealth/pyeddl/master,DeepHealth/pyecvl/master',
      threshold: hudson.model.Result.SUCCESS)
  }
  environment {
    BASE_SRC = "/usr/local/src"
    ECVL_SRC = "${BASE_SRC}/ecvl"
    EDDL_SRC = "${BASE_SRC}/eddl"
    PYECVL_SRC = "${BASE_SRC}/pyecvl"
    PYEDDL_SRC = "${BASE_SRC}/pyeddl"
    
    // Docker credentials
    registryCredential = 'dockerhub-deephealthproject'
    // Skip DockerHub
    DOCKER_LOGIN_DONE = true
    DOCKER_USER = "deephealth"
    DOCKER_BASE_IMAGE_VERSION_TAG = "0.1.8"
  }
  stages {

    stage('Configure') {
      steps {
        // Load tags
        sh 'git fetch --tags'
        
        
        script {
          // Set defaults
          ECVL_REVISION = sh(returnStdout: true, script: "git ls-remote ${ECVL_REPOSITORY} ${ECVL_BRANCH} | awk '{print \$1}'").trim()
          PYECVL_REVISION = sh(returnStdout: true, script: "git ls-remote ${PYECVL_REPOSITORY} ${PYECVL_BRANCH} | awk '{print \$1}'").trim()
          EDDL_REVISION = sh(returnStdout: true, script: "git ls-remote ${EDDL_REPOSITORY} ${EDDL_BRANCH} | awk '{print \$1}'").trim()
          PYEDDL_REVISION = sh(returnStdout: true, script: "git ls-remote ${PYEDDL_REPOSITORY} ${PYEDDL_BRANCH} | awk '{print \$1}'").trim()
          REPO_TAG = sh(returnStdout: true, script: "tag=\$(git tag -l --points-at HEAD); if [[ -n \${tag} ]]; then echo \${tag}; else git rev-parse --short HEAD --short; fi").trim()
          NORMALIZED_BRANCH_NAME = sh(returnStdout: true, script: "echo ${BRANCH_NAME} | sed 's+/+-+g'").trim()
          DOCKER_IMAGE_LATEST = sh(returnStdout: true, script: "if [ '${GIT_BRANCH}' = 'master' ]; then echo 'true'; else echo 'false'; fi").trim()
          // Extract upstream project
          currentBuild.upstreamBuilds?.each { b ->
            upstream_data = b.getBuildVariables()
            UPSTREAM_GIT_REPO = upstream_data["GIT_URL"]
            UPSTREAM_GIT_BRANCH = upstream_data["GIT_BRANCH"]
            UPSTREAM_GIT_COMMIT = upstream_data["GIT_COMMIT"].substring(0,7)
            UPSTREAM_PROJECT_DATA = upstream_data
            test = "git@github.com:kikkomep/dtests.git"
          

            BUILD_NUMBER = "34"

            // overwrite repo tag using the upstream repo
            REPO_TAG = sh(returnStdout: true, script: "git ls-remote --tags ${UPSTREAM_GIT_REPO} |  sed -nE  's+(${UPSTREAM_GIT_COMMIT})[[:space:]]*refs/tags/([[:alnum:]]{1,})+\2+p'").trim()
            NORMALIZED_BRANCH_NAME = sh(returnStdout: true, script: "echo ${UPSTREAM_GIT_BRANCH} | sed -e 's+origin/++; s+/+-+g'").trim()
            DOCKER_IMAGE_LATEST = sh(returnStdout: true, script: "if [ '${UPSTREAM_GIT_BRANCH}' = 'master' ]; then echo 'true'; else echo 'false'; fi").trim()

            // Define Docker Image TAG
            TAG = sh(returnStdout: true, script: "if [ -n '${REPO_TAG}' ]; then echo ${REPO_TAG}; else echo ${UPSTREAM_GIT_COMMIT}; fi").trim()
            DOCKER_IMAGE_TAG = "${TAG}_build${BUILD_NUMBER}"
            DOCKER_IMAGE_TAG_EXTRA = "${TAG} ${NORMALIZED_BRANCH_NAME}_build${BUILD_NUMBER}"
            
            // TODO: set revisions
            switch(UPSTREAM_GIT_REPO){
              case EDDL_REPOSITORY:
                EDDL_BRANCH = UPSTREAM_GIT_BRANCH
                EDDL_REVISION = UPSTREAM_GIT_COMMIT
                EDDL_IMAGE_VERSION_TAG = DOCKER_IMAGE_TAG
              case ECVL_REPOSITORY:
                ECVL_BRANCH = UPSTREAM_GIT_BRANCH
                ECVL_REVISION = UPSTREAM_GIT_COMMIT
                ECVL_IMAGE_VERSION_TAG = DOCKER_IMAGE_TAG
              case PYEDDL_REPOSITORY:
                PYEDDL_BRANCH = UPSTREAM_GIT_BRANCH
                PYEDDL_REVISION = UPSTREAM_GIT_COMMIT
                PYEDDL_IMAGE_VERSION_TAG = DOCKER_IMAGE_TAG
              case PYECVL_REPOSITORY:
                PYECVL_BRANCH = UPSTREAM_GIT_BRANCH
                PYECVL_REVISION = UPSTREAM_GIT_COMMIT
                PYECVL_IMAGE_VERSION_TAG = DOCKER_IMAGE_TAG
              case test:
                ECVL_REVISION = UPSTREAM_GIT_COMMIT
                echo "Test REPOSITORY: $ECVL_REVISION $UPSTREAM_GIT_COMMIT"
              default:
                echo "Default repo"
            }
          }
        }
        // Print current environment (just for debug)
        sh 'printenv'
      }
    }

    stage('Use configured variable') {
      when {
        expression { return "${UPSTREAM_PROJECT_DATA}" != "" }
      }

      steps {
        sh "echo ${UPSTREAM_GIT_REPO}"
        sh "echo ${UPSTREAM_GIT_BRANCH}"
        sh "echo ${UPSTREAM_GIT_COMMIT}"
        sh "echo ${UPSTREAM_PROJECT_DATA}"
        sh "echo ${REPO_TAG}"
        sh "echo ${NORMALIZED_BRANCH_NAME}"
        sh "echo ${DOCKER_IMAGE_LATEST}"
        sh "echo ${DOCKER_IMAGE_TAG}"
        sh "echo ${DOCKER_IMAGE_TAG_EXTRA}"
        sh "echo ${DOCKER_BASE_IMAGE_VERSION_TAG}"
      }
    }

    stage("Docker images"){
      
      parallel {
        
        stage("EDDL"){
          environment{
            EDDL_BRANCH = "${UPSTREAM_GIT_BRANCH}"
            EDDL_REVISION = "${UPSTREAM_GIT_COMMIT}"
            EDDL_IMAGE_VERSION_TAG = "${DOCKER_IMAGE_TAG}"
          }
          stages {
            stage('EDDL Build') {
              when {
                allOf {
                  triggeredBy 'UpstreamCause' ;
                  expression { return "${UPSTREAM_GIT_REPO}" == "${EDDL_REPOSITORY}" }
                }
              }
              
              steps {
                
                  sh "echo ${UPSTREAM_GIT_REPO}"
                  sh "echo ${UPSTREAM_GIT_BRANCH}"
                  sh "echo ${UPSTREAM_GIT_COMMIT}"
                  sh "echo ${UPSTREAM_PROJECT_DATA}"
                  sh "echo ${REPO_TAG}"
                  sh "echo ${NORMALIZED_BRANCH_NAME}"
                  sh "echo ${DOCKER_IMAGE_LATEST}"
                  sh "echo ${DOCKER_IMAGE_TAG}"
                  sh "echo ${DOCKER_IMAGE_TAG_EXTRA}"
                  sh "echo ${DOCKER_BASE_IMAGE_VERSION_TAG}"
                  sh "CONFIG_FILE='' make build_eddl"
                  // docker.withRegistry( '', registryCredential ) {
                  //     sh 'CONFIG_FILE="" DOCKER_IMAGE_TAG_EXTRA="" make push_libs_toolkit'
                  //     sh 'CONFIG_FILE="" DOCKER_IMAGE_TAG_EXTRA="" make push_pylibs_toolkit'
                  // }
                
              }
            }
            stage('Test EDDL') {
              // when {
              //   anyOf {
              //     expression { return "${UPSTREAM_GIT_REPO}" == "${EDDL_REPOSITORY}" }
              //     expression { return "${UPSTREAM_GIT_REPO}" == "" }
              //   }
              // }
              // environment{
              //   EDDL_BRANCH = "${UPSTREAM_GIT_BRANCH}"
              //   EDDL_REVISION = "${UPSTREAM_GIT_COMMIT}"
              //   EDDL_IMAGE_VERSION_TAG = "${DOCKER_IMAGE_TAG}"
              // }
              // agent {
              //   docker { image '${DOCKER_REPOSITORY_OWNER}/libs-toolkit:${EDDL_IMAGE_VERSION_TAG}' }
              // }
              steps {
                sh "echo 'Testing eddl-toolkit:${EDDL_IMAGE_VERSION_TAG}'"
                sh 'docker run --rm eddl-toolkit:${EDDL_IMAGE_VERSION_TAG} /bin/bash -c "cd ${EDDL_SRC}/build && ctest -C Debug -VV"'
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
  } 
}