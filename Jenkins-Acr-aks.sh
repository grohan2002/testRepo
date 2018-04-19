# Pipeline Script for ACR and AKS collaboration . You should have a vaild Microsoft account for this to work

node {
      // Mark the code checkout 'stage'....
        stage('Checkout the dockefile from GitHub') {
            //git url: 'https://github.com/jldeen/swampup2017'
            sh 'rm -rf /var/lib/jenkins/workspace/AzurePipeline/*'
            sh 'docker system prune -f -a'
            // git branch: 'docker-file', credentialsId: '96f735c7-cea2-431a-859f-969e9f1c8809', url: 'https://gitlab.com/simplifimed/simplifimed-enterprise.git'
            git branch: 'docker-file', credentialsId: 'git_credentials', url: 'https://gitlab.com/simplifimed/simplifimed-enterprise.git'
            sh 'cp -ip /var/lib/jenkins/workspace/AzurePipeline/app/Dockerfile /var/lib/jenkins/workspace/AzurePipeline/'
            sh 'cp -ip /var/lib/jenkins/workspace/AzurePipeline/app/config.json /var/lib/jenkins/workspace/AzurePipeline/config.json'
        }

        // Build and Deploy to ACR 'stage'...
        stage('Build the Image and Push to Azure Container Registry') {
                app = docker.build('simplimedacr.azurecr.io/bot-demo')
                withDockerRegistry([credentialsId: 'acr_credentials', url: 'https://simplimedacr.azurecr.io']) {
                app.push("${env.BUILD_NUMBER}")
                app.push('latest')
                }
        }


        stage('Build the Kubernetes YAML Files for New App') {
        
            sh 'mkdir -p /home/jenkins/$botName'
            sh 'cp -ip /home/jenkins/kubernetes/*.yaml /home/jenkins/$botName'
            sh 'mv /home/jenkins/$botName/bot-deployment.yaml /home/jenkins/$botName/$botName-deployment.yaml && mv /home/jenkins/$botName/bot-service.yaml /home/jenkins/$botName/$botName-service.yaml'
            sh "cd /home/jenkins/$botName && sed -i -- 's/bot1/$botName/g' *"
            
        }
    
        stage('Delpoying the App on Azure Kubernetes Service') {
            app = docker.image('simplimedacr.azurecr.io/bot-demo:latest')
            withDockerRegistry([credentialsId: 'acr_credentials', url: 'https://simplimedacr.azurecr.io']) {
            app.pull()
            sh "cd /home/jenkins/$botName && kubectl create -f ."
            }

        }
    }
