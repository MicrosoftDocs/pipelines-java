
pipeline {
    agent { docker { image 'ghcr.io/hadolint/hadolint:v2.3.0-alpine' } }
    
    parameters {
    string(name: 'lint-dockerfile', defaultValue: 'true', description: 'lint dockerfile')
    string(name: 'dockerfile', defaultValue: 'Dockerfile', description: 'dockerfile')
}
    
    environment {
         FILE="$(params.source-dir)"/.hadolint.yaml
    }
    stages {
        stage('lint-dockerfile') {
            steps {
                sh 'mvn --version'
            }
        }
    }
}
