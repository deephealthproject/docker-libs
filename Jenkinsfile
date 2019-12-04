pipeline {
  agent any
  environment {
    BASE_SRC = "/usr/local/src"
    ECVL_SRC = "${BASE_SRC}/ecvl"
    EDDL_SRC = "${BASE_SRC}/eddl"
    PYECVL_SRC = "${BASE_SRC}/pyecvl"
    PYEDDL_SRC = "${BASE_SRC}/pyeddl"
    // ECVL Settings
    ECVL_REPOSITORY = "git@github.com:deephealthproject/ecvl.git"
    ECVL_BRANCH = "master"
    ECVL_REVISION = sh(returnStdout: true, script: "git ls-remote https://github.com/deephealthproject/ecvl.git ${ECVL_BRANCH} | awk '{print \$1}'").trim()
    // PyECVL Settings
    PYECVL_REPOSITORY = "git@github.com:deephealthproject/pyecvl.git"
    PYECVL_BRANCH = "master"
    PYECVL_REVISION = sh(returnStdout: true, script: "git ls-remote https://github.com/deephealthproject/pyecvl.git ${PYECVL_BRANCH} | awk '{print \$1}'").trim()
    // EDDL Settings    
    EDDL_REPOSITORY = "git@github.com:deephealthproject/eddl.git"
    EDDL_BRANCH = "master"
    EDDL_REVISION = sh(returnStdout: true, script: "git ls-remote https://github.com/deephealthproject/eddl.git ${EDDL_BRANCH} | awk '{print \$1}'").trim()
    // PyEDDL Settings
    PYEDDL_REPOSITORY = "git@github.com:deephealthproject/pyeddl.git"
    PYEDDL_BRANCH = "master"
    PYEDDL_REVISION = sh(returnStdout: true, script: "git ls-remote https://github.com/deephealthproject/pyeddl.git ${PYEDDL_BRANCH} | awk '{print \$1}'").trim()
    // Docker Settings
    DOCKER_IMAGE_LATEST = sh(returnStdout: true, script: "if [[ ${GIT_BRANCH} == 'master' ]]; then echo 'true'; else echo 'false'; fi")
    DOCKER_IMAGE_TAG = sh(returnStdout: true, script: "if [[ ${GIT_BRANCH} == 'master' ]]; then echo 'build-${BUILD_NUMBER}' ; else echo 'dev-build-${BUILD_NUMBER}' ; fi").trim()
    DOCKER_IMAGE_RELEASE_TAG = sh(returnStdout: true, script: "grep DOCKER_IMAGE_TAG settings.sh | awk -F'[=]' '{print \$2}'").trim()
  }
  stages {
    stage('Configure') {
      steps {
        sh 'printenv'
      }
    }
    stage('Build') {
      when {
          { branch 'master' }
      }
      steps {        
        sh 'CONFIG_FILE="" make build'
      }
    }
    stage('Build Release') {
      when {
          not { branch "master" }
      }
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
          branch 'master'
      }
      steps {        
          sh 'CONFIG_FILE="" make push'
      }
    }
    stage('Deploy Release') {
      when {
          not { branch "master" }
      }
      steps {
        withEnv (['DOCKER_IMAGE_TAG_EXTRA=${DOCKER_IMAGE_RELEASE_TAG} ${DOCKER_IMAGE_RELEASE_TAG}_${DOCKER_IMAGE_TAG}"']){
          sh 'make push'
        }
      }
    }
  }
  post {
    always {
      echo 'One way or another, I have finished'
      deleteDir() /* clean up our workspace */
    }
    success {
      echo "Docker images successfully build and published with tags: ${DOCKER_IMAGE_TAG}"
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
      mail to: "kikkomep@crs4.it"
           bcc: '', 
           cc: '', 
           body: "<b>Example</b><br>Project: ${env.JOB_NAME} <br>Build Number: ${env.BUILD_NUMBER} <br> URL de build: ${env.BUILD_URL}",
           charset: 'UTF-8', from: '', 
           mimeType: 'text/html', replyTo: '', 
           subject: "ERROR CI: Project name -> ${env.JOB_NAME}";
      
      echo 'I failed :('
    }
    changed {
      echo 'Things were different before...'
    }
  } 
}