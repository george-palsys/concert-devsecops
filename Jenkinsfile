pipeline {
    agent { label 'RHEL-9.3' }

    environment {
        DOCKER_IMAGE = 'docker.io/georgechiu/insecure-bank'
        BUILD_NUMBER = 'v1'
        DOCKER_HUB_REPO = 'georgechiu/insecure-bank'
        NEXUS_REPO_URL = 'http://10.107.85.174:8081/repository/insecurity-bank-artifacts/'
        BLACKDUCK_URL = 'https://10.107.85.166/'
        OCP_NAMESPACE = 'concert-demo'
        OCP_DEPLOYMENT = 'insecurity-bank'
        BLACKDUCK_ACCESS_TOKEN = 'Yjk5OWU5Y2MtNjA1Yi00YTA5LWFkY2EtMWY2YmU2YmFjNmQ3OjM2NDVjNGJhLWUzYjItNGIxMi1iZTEyLWJiNTU0ODViZmUwYw=='
        BLACKDUCK_PROJECT_NAME = 'insecure-bank-demo'
        BLACKDUCK_VERSION_NAME = 'developerment'
        SRC_PATH = '.'
    }

    stages {
        stage('Clean Workspace') {
             steps {
        deleteDir()  
            }
        }
        stage('Checkout Source Code') {
            steps {
                git branch: 'main', url: 'https://github.com/george-palsys/concert-devsecops.git'
            }
        }

        stage('Build & Package') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }

        stage('SCA Scan with Black Duck') {
            steps {
                    sh """
                        curl -s -L https://detect.blackduck.com/detect10.sh -o detect10.sh
                        bash detect10.sh --blackduck.url=${env.BLACKDUCK_URL} \
                                         --blackduck.api.token=${env.BLACKDUCK_ACCESS_TOKEN} \
                                         --blackduck.trust.cert=true \
                                         --detect.output.path=output \
                                         --detect.detector.search.depth=5 \
                                         --detect.project.name=${env.BLACKDUCK_PROJECT_NAME} \
                                         --detect.project.version.name=${env.BLACKDUCK_VERSION_NAME} \
                                         --detect.source.path=${env.SRC_PATH}
                    """
            }
        }

        stage('Publish to Nexus') {
            steps {
                    nexusArtifactUploader artifacts: [[artifactId: 'insecure-bank', classifier: '', file: 'target/insecure-bank.war', type: 'war']], credentialsId: 'nexus', groupId: 'in.javahome', nexusUrl: '10.107.85.174:8081', nexusVersion: 'nexus3', protocol: 'http', repository: 'insecurity-bank-artifacts-hosted', version: '1.0.0'
           }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t docker.io/$DOCKER_HUB_REPO:$BUILD_NUMBER ."
            }
        }
        

        stage ('Push Docker Image to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', passwordVariable: 'password', usernameVariable: 'username')]){
               sh '''
                    docker login -u $username -p $password
                    docker push $DOCKER_HUB_REPO:$BUILD_NUMBER
                '''
              }
            }
        }

        stage ('Loggin ArgoCD') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'argocd-credential', passwordVariable: 'password', usernameVariable: 'username')]){
               sh '''
                    argocd login openshift-gitops-server-openshift-gitops.apps.george.ocplab.com --username $username --password $password  --insecure
                    argocd app create insecure-bank-dev --repo https://github.com/george-palsys/concert-devsecops-manifests.git --path insecure-bank-dev --dest-server https://kubernetes.default.svc --dest-namespace insecure-bank-dev
                '''
              }
            }
        }

        stage('Trigger ArgoCD Deployment') {
            steps {
                sh "argocd app sync insecure-bank-dev"
            }
        }
    }
}
