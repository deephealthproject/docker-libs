pipeline {
  agent any
  environment {
    BASE_SRC = "/usr/local/src"
    ECVL_SRC = "${BASE_SRC}/ecvl"
    EDDL_SRC = "${BASE_SRC}/eddl"
    PYECVL_SRC = "${BASE_SRC}/pyecvl"
    PYEDDL_SRC = "${BASE_SRC}/pyeddl"
    //LIBRARY_BRANCH = sh(returnStdout: true, script: "if [[ ${GIT_BRANCH} != 'master' && ${GIT_BRANCH} != 'develop' ]]; then echo 'develop'; else echo ${GIT_BRANCH}; fi")
    LIB_BRANCH = "master"
    ECVL_REVISION = sh(returnStdout: true, script: "git ls-remote https://github.com/deephealthproject/ecvl.git ${LIB_BRANCH} | awk '{print \$1}'")
    EDDL_REVISION = sh(returnStdout: true, script: "git ls-remote https://github.com/deephealthproject/eddl.git ${LIB_BRANCH} | awk '{print \$1}'")
    PYECVL_REVISION = sh(returnStdout: true, script: "git ls-remote https://github.com/deephealthproject/pyecvl.git ${LIB_BRANCH} | awk '{print \$1}'")
    PYEDDL_REVISION = sh(returnStdout: true, script: "git ls-remote https://github.com/deephealthproject/pyeddl.git ${LIB_BRANCH} | awk '{print \$1}'")
    DOCKER_IMAGE_LATEST = sh(returnStdout: true, script: "if [[ ${GIT_BRANCH} == 'master' ]]; then echo 'true'; else echo 'false'; fi")
    DOCKER_IMAGE_TAG = sh(returnStdout: true, script: "if [[ ${GIT_BRANCH} == 'master' ]]; then echo 'build-${BUILD_NUMBER}'; else echo 'dev-build-${BUILD_NUMBER}'; fi")
  }
  stages {
    stage('printenv') {
      steps {
        sh 'printenv'
      }
    }
    stage('Build') {
      steps {
          sh 'make build'
      }
    }
    stage('Test EDDL') {
      agent {
        docker { image 'libs-toolkit:${DOCKER_IMAGE_TAG}' }
      }
      steps {
        sh 'cd ${EDDL_SRC}/build && ctest -C Debug -VV'
      }
    }
    stage('Test ECVL') {
      agent {
        docker { image 'libs-toolkit:${DOCKER_IMAGE_TAG}' }
      }
      steps {
        sh 'cd ${ECVL_SRC}/build && ctest -C Debug -VV'
      }
    }
    stage('Test PyEDDL') {
      agent {
        docker { image 'pylibs-toolkit:${DOCKER_IMAGE_TAG}' }
      }
      steps {
        sh 'cd ${PYEDDL_SRC} && pytest tests'
        sh 'cd ${PYEDDL_SRC}/examples && python3 Tensor/eddl_tensor.py'
        sh 'cd ${PYEDDL_SRC}/examples && bash NN/run_all_fast.sh'
      }
    }
    stage('Test PyECVL') {
      agent {
        docker { image 'pylibs-toolkit:${DOCKER_IMAGE_TAG}' }
      }
      steps {
        sh 'cd ${PYECVL_SRC} && pytest tests'
        sh 'cd ${PYECVL_SRC}/examples && python3 dataset.py ${ECVL_SRC}/build/mnist/mnist.yml'
        sh 'cd ${PYECVL_SRC}/examples && python3 ecvl_eddl.py ${ECVL_SRC}/data/test.jpg ${ECVL_SRC}/build/mnist/mnist.yml'
        sh 'cd ${PYECVL_SRC}/examples && python3 img_format.py ${ECVL_SRC}/data/nifti/LR_nifti.nii ${ECVL_SRC}/data/isic_dicom/ISIC_0000008.dcm'
        sh 'cd ${PYECVL_SRC}/examples && python3 imgproc.py ${ECVL_SRC}/data/test.jpg'
        sh 'cd ${PYECVL_SRC}/examples && python3 openslide.py ${ECVL_SRC}/data/hamamatsu/10-B1-TALG.ndpi'
        sh 'cd ${PYECVL_SRC}/examples && python3 read_write.py ${ECVL_SRC}/data/test.jpg test_mod.jpg'
      }
    }

    stage('Deploy') {      
      when {
          expression {
            currentBuild.result == null || currentBuild.result == 'SUCCESS' 
          }
          branch pattern: "master|develop", comparator: "REGEXP"
      }
      steps {
        sh 'make publish'
      }
    }
    


  }
  post {
    always {
      echo 'One way or another, I have finished'
      deleteDir() /* clean up our workspace */
    }
    success {
      echo 'Docker images successfully build and published with tags: ${DOCKER_IMAGE_TAG}'
      echo 'Library revisions...'
      echo '* ECVL revision: ${ECVL_REVISION}'
      echo '* EDDL revision: ${EDDL_REVISION}'
      echo '* PyECVL revision: ${PYECVL_REVISION}'
      echo '* PyEDDL revision: ${PYEDDL_REVISION}'      
    }
    unstable {
      echo 'I am unstable :/'
    }
    failure {
      echo 'I failed :('
    }
    changed {
      echo 'Things were different before...'
    }
  } 
}