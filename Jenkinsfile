
pipeline {
    agent any
    
   
    
   
    stages {
        stage('lint-dockerfile') {
            steps {
                sh 'hadolint ./dockerfile'
            }
        }
    }
}
