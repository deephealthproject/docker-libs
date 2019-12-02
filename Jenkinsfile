pipeline {
  agent any
  environment {
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
        docker { image 'pylibs:latest' }
      }
      steps {
        sh 'cd/usr/local/src/pyecvl && pytest tests'
        sh 'cd/usr/local/src/pyecvl/examples && python3 dataset.py /ecvl/build/mnist/mnist.yml'
        sh 'cd/usr/local/src/pyecvl/examples && python3 ecvl_eddl.py /ecvl/data/test.jpg /ecvl/build/mnist/mnist.yml'
        sh 'cd/usr/local/src/pyecvl/examples && python3 img_format.py /ecvl/data/nifti/LR_nifti.nii /ecvl/data/isic_dicom/ISIC_0000008.dcm'
        sh 'cd/usr/local/src/pyecvl/examples && python3 imgproc.py /ecvl/data/test.jpg'
        sh 'cd/usr/local/src/pyecvl/examples && python3 openslide.py /ecvl/data/hamamatsu/10-B1-TALG.ndpi'
        sh 'cd/usr/local/src/pyecvl/examples && python3 read_write.py /ecvl/data/test.jpg test_mod.jpg'
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