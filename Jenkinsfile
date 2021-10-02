
pipeline {
    
   
   
    
   
    stages {
        stage('Build') {
            steps {
                sh 'mvn -B -DskipTests clean package'
            }
        }
        stage('lint-dockerfile') {
            
            agent {
        label 'nodejs'
                }
    
            steps {
                sh 'ls '
                sh 'npm install -g dockerlint'
                sh 'dockerlint Dockerfile'
            }
        }
        stage('Build) {
            
            agent {
        label 'maven'
                  }
            steps {
                sh 'ls '
                sh 'nvn clean install'
               
            }
        }
    }
}
