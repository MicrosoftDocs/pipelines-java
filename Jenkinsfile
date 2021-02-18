pipeline {
  agent any
  stages {
    stage('Buzz Build') {
      steps {
        echo 'buzz'
      }
    }

    stage('buzz test') {
      steps {
        junit '**/surefire-reports/**/*.xml'
      }
    }

  }
}