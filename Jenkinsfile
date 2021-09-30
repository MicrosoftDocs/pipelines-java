
pipeline {
    
   agent {
        label 'nodejs'
    }
    
   
    
   
    stages {
        stage('lint-dockerfile') {
            steps {
                sh 'ls '
                sh 'npm install -g dockerlint'
                sh 'dockerlint dockerfile'
            }
        }
    }
}
