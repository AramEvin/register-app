pipeline {
    agent { label 'Jenkins-Agent' }
    tools {
        jdk 'Java17'
        maven 'Maven3'
    }
	
    environment {
	    APP_NAME = "register-app-pipeline"
            RELEASE = "1.0.0"
            DOCKER_USER = "aramevinyan"
            DOCKER_PASS = 'dockerhub'
            IMAGE_NAME = "${DOCKER_USER}" + "/" + "${APP_NAME}"
            IMAGE_TAG = "${RELEASE}-${BUILD_NUMBER}"
    }
	
    stages{
        stage("Cleanup Workspace"){
                steps {
                cleanWs()
                }
        }

        stage("Checkout from SCM"){
                steps {
                    git branch: 'main', credentialsId: 'github', url: 'https://github.com/AramEvin/register-app'
                }
        }

        stage("Build Application"){
            steps {
                sh "mvn clean package"
            }

       }

       stage("Test Application"){
           steps {
                 sh "mvn test"
           }
       }
        stage("SonarQube Analysis"){
           steps {
	           script {
		        withSonarQubeEnv(credentialsId: 'SonarQube-Jenkins-Token') { 
                        sh "mvn sonar:sonar"
		        }
	           }	
           }
       }
	stage("Quality Gate"){
           steps {
               script {
                    waitForQualityGate abortPipeline: false, credentialsId: 'SonarQube-Jenkins-Token'
                }	
            }

        }
	 stage("Build & Push Docker Image") {
             steps {
                 script {
                     docker.withRegistry('',DOCKER_PASS) {
                         docker_image = docker.build "${IMAGE_NAME}"
                    }

                     docker.withRegistry('',DOCKER_PASS) {
                         docker_image.push("${IMAGE_TAG}")
                         docker_image.push('latest')
                    }
                }
            }
       }
	stage("Trivy Scan") {
           steps {
               script {
	            sh ('docker run -v /var/run/docker.sock:/var/run/docker.sock -e TRIVY_TIMEOUT=20m aquasec/trivy image aramevinyan/register-app-pipeline:latest --no-progress --scanners vuln  --exit-code 0 --severity HIGH,CRITICAL --format table')
               }
           }
       }
	stage ('Cleanup Artifacts') {
           steps {
               script {
                    sh "docker rmi ${IMAGE_NAME}:${IMAGE_TAG}"
                    sh "docker rmi ${IMAGE_NAME}:latest"
               }
          }
       } 
	stage("Debug CD Server") {
    	agent { label 'cd-server' }
		    steps {
		        sh "whoami"
		        sh "pwd"
		        sh "docker --version"
		        sh "docker ps || true"
   		}
	}	
		
	stage("Deploy to CD Server") {
    	agent { label 'cd-server' }
    		steps {
        		sh """
        		echo "${DOCKER_CREDS_PSW}" | docker login -u "${DOCKER_CREDS_USR}" --password-stdin
        		docker pull ${IMAGE_NAME}:${IMAGE_TAG}
        		docker stop ${APP_NAME} || true
        		docker rm ${APP_NAME} || true
        		docker run -d --name ${APP_NAME} --restart unless-stopped -p 8080:8080 ${IMAGE_NAME}:${IMAGE_TAG}"""
    		}
		}
	
   }
}
