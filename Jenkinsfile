
node {
    checkout scm

    //docker.withServer('tcp://172.31.43.67:4243')
     docker.withServer('tcp://localhost:4243'.'swarm-certs'){
        // def customImage = docker.build("my-image:${env.BUILD_ID}")
       //  customImage.push()

       //  customImage.push('latest')
        
         def maven = docker.image('maven:latest')
         maven.pull() // make sure we have the latest available from Docker Hub
         maven.inside {
        // git '…your-sources…'
        sh 'mvn -B clean install'
  }
        }
    
}
