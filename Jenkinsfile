
pipeline {
    
   agent {
        label 'nodejs'
    }
    
   
    
   
    stages {
        stage('lint-dockerfile') {
            steps {
                sh 'npm install -g dockerlint'
                sh 'dockerlint dockerfile'
            }
        }
    }
}
