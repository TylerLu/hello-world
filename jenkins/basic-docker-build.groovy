node {
    def built_img = ''
    def taggedImageName = ''
    stage('Checkout git repo') {
      git branch: 'master', url: params.git_repo
    }
    stage('Build Docker image') {
      built_img = docker.build(params.docker_repository + ":${env.BUILD_NUMBER}", '.')
    }
    stage('Push Docker image to Azure Container Registry') {
      docker.withRegistry(params.registry_url, params.registry_credentials_id ) {
        taggedImageName = built_img.tag("${env.BUILD_NUMBER}")
        built_img.push("${env.BUILD_NUMBER}");
      }
    }
    stage('Deploy configurations to Azure Container Service (AKS)') {
      withEnv(['IMAGE_NAME=' + taggedImageName]) {
        acsDeploy azureCredentialsId: params.azure_service_principal_id, configFilePaths: 'kubernetes/*.yaml', containerService: params.aks_cluster_name + ' | AKS', dcosDockerCredentialsPath: '', enableConfigSubstitution: true, resourceGroupName: params.aks_resource_group_name, secretName: '', sshCredentialsId: ''
      }
    }
}