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
        dir('cd /tmp'){
          sh 'pwd'
          sh 'ls .'
        }
      }
    }
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
    stage('Test PyECVL') {
      agent {
        docker { image 'pylibs:latest' }
      }
      steps {
        dir('cd /usr/local/src/pyecvl'){
          sh 'pwd'
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