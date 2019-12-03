pipeline {
  agent any
  environment {
    BASE_SRC = "/usr/local/src"
    ECVL_SRC = "${BASE_SRC}/ecvl"
    EDDL_SRC = "${BASE_SRC}/eddl"
    PYECVL_SRC = "${BASE_SRC}/pyecvl"
    PYEDDL_SRC = "${BASE_SRC}/pyeddl"
    ECVL_REVISION = sh(returnStdout: true, script: "git ls-remote https://github.com/deephealthproject/ecvl.git master | awk '{print \$1}'")
    EDDL_REVISION = sh(returnStdout: true, script: "git ls-remote https://github.com/deephealthproject/eddl.git master | awk '{print \$1}'")
    DOCKER_IMAGE_LATEST = sh(returnStdout: true, script: "if [[ ${GIT_BRANCH} == 'master' ]]; then echo 'true'; else echo 'false'; fi")
    BUILD_NUMBER = sh(returnStdout: true, script: "if [[ ${GIT_BRANCH} == 'master' ]]; then echo '${BUILD_NUMBER}'; else echo '${GIT_BRANCH}-${BUILD_NUMBER}'; fi")
    DOCKER_IMAGE_TAG_PREFIX = sh(returnStdout: true, script: "if [[ ${GIT_BRANCH} != 'master' ]]; then echo '${GIT_BRANCH}'; fi")
    DOCKER_IMAGE_TAG = sh(returnStdout: true, script: "echo ${DOCKER_IMAGE_TAG_PREFIX} | tr -d \/")
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
        docker { image 'libs-toolkit:latest' }
      }
      steps {
        sh 'cd ${EDDL_SRC}/build && ctest -C Debug -VV'
      }
    }
    stage('Test ECVL') {
      agent {
        docker { image 'libs-toolkit:latest' }
      }
      steps {
        sh 'cd ${ECVL_SRC}/build && ctest -C Debug -VV'
      }
    }
    stage('Test PyEDDL') {
      agent {
        docker { image 'pylibs-toolkit:latest' }
      }
      steps {
        sh 'cd ${PYEDDL_SRC} && pytest tests'
        sh 'cd ${PYEDDL_SRC}/examples && python3 Tensor/eddl_tensor.py'
        sh 'cd ${PYEDDL_SRC}/examples && bash NN/run_all_fast.sh'
      }
    }
    stage('Test PyECVL') {
      agent {
        docker { image 'pylibs-toolkit:latest' }
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
      echo 'I succeeded!'
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