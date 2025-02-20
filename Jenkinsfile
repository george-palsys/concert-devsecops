pipeline {
    agent { label 'RHEL-9.3' }

    environment {
        DOCKER_IMAGE = 'docker.io/georgechiu/liberity'
        BUILD_NUMBER = 'v1'
        DOCKER_HUB_REPO = 'georgechiu/liberity'
        NEXUS_REPO_URL = 'http://10.107.85.174:8081/repository/liberity/'
        BLACKDUCK_URL = 'https://10.107.85.166/'
        BLACKDUCK_HOSTNAME = 'https://webserver'
        OCP_NAMESPACE = 'concert-demo'
        OCP_DEPLOYMENT = 'liberity'
        BLACKDUCK_ACCESS_TOKEN = 'Yjk5OWU5Y2MtNjA1Yi00YTA5LWFkY2EtMWY2YmU2YmFjNmQ3OjM2NDVjNGJhLWUzYjItNGIxMi1iZTEyLWJiNTU0ODViZmUwYw=='
        BLACKDUCK_PROJECT_NAME = 'liberity-demo'
        BLACKDUCK_VERSION_NAME = 'developerment'
        SRC_PATH = '.'
        ARGOCD_AP_NAME = 'liberity-dev'
        MANIFESTS_REPO = 'https://github.com/george-palsys/concert-devsecops-manifests.git'
        ARGOCD_PATH = 'liberity-dev'
        DEST_SERVER = 'https://kubernetes.default.svc'
        ARGOCD_DEPLOY_NAMESPACE = 'liberity-dev'
        ARGOCD_SERVER= 'openshift-gitops-server-openshift-gitops.apps.george.ocplab.com'
        PROJECT_ID = "9eaddc28-a4e3-49b3-b59f-e5161d7bf599"
        PROJECT_VERSION_ID = "9126f7b9-0204-4f1d-8d78-461999a3ac3b"
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
                        bash detect10.sh --blackduck.url=${env.BLACKDUCK_HOSTNAME} \
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
                    nexusArtifactUploader artifacts: [[artifactId: 'guide-getting-started', classifier: '', file: 'target/guide-getting-started.war', type: 'war']], credentialsId: 'nexus', groupId: 'io.openliberty.guides', nexusUrl: '10.107.85.174:8081', nexusVersion: 'nexus3', protocol: 'http', repository: 'liberity', version: '1.0.0'
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
                    argocd login $ARGOCD_SERVER --username $username --password $password  --insecure
                    argocd app create $ARGOCD_AP_NAME --repo $MANIFESTS_REPO --path $ARGOCD_PATH --dest-server $DEST_SERVER --dest-namespace $ARGOCD_DEPLOY_NAMESPACE
                '''
              }
            }
        }

        stage('Trigger ArgoCD Deployment') {
            steps {
                sh "argocd app sync $ARGOCD_AP_NAME"
            }
        }

        stage('Get OAuth Token') {
            steps {
                script {
                    def authResponse = httpRequest(
                        url: "${BLACKDUCK_HOSTNAME}/api/tokens/authenticate",
                        httpMode: 'POST',
                        customHeaders: [[name: 'Authorization', value: "token ${BLACKDUCK_ACCESS_TOKEN}"]],
                        acceptType: 'APPLICATION_JSON'
                    )
                    
                    def authJson = readJSON text: authResponse.content
                    env.BEARER_TOKEN = authJson.bearerToken
                    echo "Obtained Bearer Token"


                    // 先打印返回内容，确保是 JSON
                    echo "Auth Response: ${authResponse.content}"

                    if (authResponse.content?.trim()) {
                        authJson = readJSON text: authResponse.content
                        env.BEARER_TOKEN = authJson.bearerToken
                        echo "Obtained Bearer Token"
                    } else {
                        error "Failed to obtain Bearer Token: Empty response from API"
                    }
                }
            }
        }

        stage('Generate SBOM Report') {
            steps {
                script {
                  def reportResponse = httpRequest(
                        url: "${BLACKDUCK_HOSTNAME}/api/projects/${PROJECT_ID}/versions/${PROJECT_VERSION_ID}/sbom-reports",
                       httpMode: 'POST',
                      contentType: 'APPLICATION_JSON',
                     customHeaders: [[name: 'Authorization', value: "Bearer ${env.BEARER_TOKEN}"]],
                     requestBody: '''{
                            "reportFormat": "JSON",
                            "sbomType": "CYCLONEDX_15"
                        }'''
                    )

                }
            }
        }


        stage('Download SBOM Report') {
            steps {
                script {
                    def downloadUrl = "${BLACKDUCK_HOSTNAME}/api/projects/${PROJECT_ID}/versions/${PROJECT_VERSION_ID}/reports/${env.REPORT_ID}/download"
                    
                    sh "curl -X GET -H 'Authorization: Bearer ${env.BEARER_TOKEN}' -o sbom_report.json ${downloadUrl}"
                    echo "Downloaded SBOM Report"
                }
            }
        }
    }
}
