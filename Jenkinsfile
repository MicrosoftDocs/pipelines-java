node('linux') {
  def maven = docker.image('maven:latest')
  maven.pull() // make sure we have the latest available from Docker Hub
  maven.inside {
   git 'https://github.com/chejuro1/pipelines-java.git'
  }
}
