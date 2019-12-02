pipeline {
  agent any
  stages {
    stage('build') {
        steps {
          dir('Clone test') {
            git url: 'https://github.com/deephealthproject/ecvl.git'
            sh 'cat README.md'
          }
        },
        steps {
          sh 'make build'
      }
    }
  }
}