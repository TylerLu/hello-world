node {
    def built_img = ''
    def taggedImageName = ''
    stage('Checkout git repo') {
      git branch: 'master', url: params.GIT_REPO
    }
    stage('Build Docker image') {
      built_img = docker.build(params.DOCKER_REPOSITORY + ":${env.BUILD_NUMBER}", '.')
    }
    stage('Push Docker image to Azure Container Registry') {
      docker.withRegistry(params.registry_url, params.registry_credentials_id ) {
        taggedImageName = built_img.tag("${env.BUILD_NUMBER}")
        built_img.push("${env.BUILD_NUMBER}");
      }
    }
    stage('Deploy configurations to Azure Container Service (AKS)') {
      withEnv(['TAGGED_IMAGE_NAME=' + taggedImageName]) {
        acsDeploy azureCredentialsId: params.AZURE_SERVICE_PRINCIPAL_ID, configFilePaths: 'kubernetes/*.yaml', containerService: params.AKS_CLUSTER_NAME + ' | AKS', dcosDockerCredentialsPath: '', enableConfigSubstitution: true, resourceGroupName: params.AKS_RESOURCE_GROUP_NAME, secretName: '', sshCredentialsId: ''
      }
    }
}