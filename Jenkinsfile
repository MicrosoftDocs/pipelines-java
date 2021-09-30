
pipeline {
    
   agent {
        label 'maven'
    }
    
   
    
   
    stages {
        stage('lint-dockerfile') {
            steps {
                sh 'hadolint ./dockerfile'
            }
        }
    }
}
