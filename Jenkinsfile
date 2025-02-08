pipeline {
    agent { label 'RHEL-9.3' }

    environment {
        DOCKER_IMAGE = 'georgechiu/insecure-bank:v1'
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



        stage('Publish to Nexus2') {
            steps {
                nexusArtifactUploader(
                credentialsId: 'your-nexus-credentials-id',
                groupId: 'com.demo.project',
                artifactId: 'insecure-bank',
                version: '1.0.0',
                nexusUrl: "${NEXUS_REPO_URL}",
                nexusVersion: 'nexus3',
                protocol: 'http',
                repository: 'snapshots',
                artifacts: [[
                artifactId: 'insecure-bank',
                classifier: '',
                file: 'target/insecure-bank-1.0.0.war'
                ]]
                )
            }
       }



        stage('Build Docker Image') {
            steps {
                sh "docker build -t $DOCKER_HUB_REPO:$BUILD_NUMBER ."
            }
        }

        stage('Push Docker Image to Docker Hub') {
            steps {
                withDockerRegistry([credentialsId: 'docker-hub-credentials', url: '']) {
                    sh "docker push $DOCKER_HUB_REPO:$BUILD_NUMBER"
                }
            }
        }

        stage('Trigger ArgoCD Deployment') {
            steps {
                sh "argocd app sync my-app"
            }
        }

        stage('Deploy to OpenShift') {
            steps {
                sh """
                oc project $OCP_NAMESPACE
                oc set image deployment/$OCP_DEPLOYMENT my-app=$DOCKER_HUB_REPO:$BUILD_NUMBER
                oc rollout restart deployment/$OCP_DEPLOYMENT
                """
            }
        }
    }
}
