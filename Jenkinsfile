pipeline {
    agent any
    tools {
        // Install the Maven version configured as "M3" and add it to the path.
        maven "M3"
    }
    stages {
        stage ('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/rudranshrocks7/pipelines-java.git'
            }
        }
        stage('Build') {
            steps {
                sh "mvn -Dmaven.test.failure.ignore=true clean package"
            }
        }
        stage('Install') {
            steps {
                sh "mvn install"
            }
        }
        stage ('Deploy') {
            when {
                branch 'main'
            }
            steps {
                echo "Deploying"
                deploy adapters: [tomcat9 (
                    credentialsId: 'tomcat',
                    path: '',
                    url: 'http://74.249.99.250:8088/'
                )],
                contextPath: 'finalTest',
                onFailure: 'false',
                war: '**/*.war'
            }
            post {
                success {
                    junit '**/target/surefire-reports/TEST-*.xml'
                    archiveArtifacts 'target/*.war'
                }
            }
        }
    }
}
