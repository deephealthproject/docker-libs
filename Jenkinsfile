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
          sh 'ls .'
        }
    }
    stage('printenv') {
        steps {
          sh 'printenv'
        }
    }
    stage('build') {
        steps {
          sh 'make build'
      }
    }
  }
}