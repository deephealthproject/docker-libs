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
  }
  stages {
    stage('print pwd') {
      steps {
        sh 'pwd'
        dir('tests'){
          sh 'pwd'
          sh 'ls .'
        }
        sh 'pwd'
      }
    }
    stage('printenv') {
      steps {
        sh 'printenv'
      }
    }
    // stage('Build') {
    //   steps {
    //       sh 'make build'
    //   }
    // }
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