
node {
    checkout scm

    docker.withServer('tcp://172.31.43.67:4243') {
         def customImage = docker.build("my-image:${env.BUILD_ID}")
         customImage.push()

         customImage.push('latest')
        }
    
}
