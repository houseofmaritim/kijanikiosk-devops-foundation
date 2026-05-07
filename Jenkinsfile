pipeline {
    agent any

    environment {
        APP_NAME = "kijanikiosk"
        DOCKER_REPO = "localhost:8082/kijanikiosk-docker"
        IMAGE_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT?.take(7)}"
        FULL_IMAGE = "${DOCKER_REPO}/${APP_NAME}"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Init') {
            steps {
                script {
                    env.GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.BUILD_VERSION = "0.1.0-${env.GIT_SHA}"
                    echo "Build version: ${env.BUILD_VERSION}"
                }
            }
        }

        stage('Lint') {
            steps {
                sh 'echo "Lint stage: placeholder"'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t ${APP_NAME}:${env.BUILD_VERSION} -f app/Dockerfile .
                        
                        docker tag ${APP_NAME}:${env.BUILD_VERSION} ${FULL_IMAGE}:${env.BUILD_VERSION}
                        docker tag ${APP_NAME}:${env.BUILD_VERSION} ${FULL_IMAGE}:latest
                    """
                }
            }
        }

        stage('Verify') {
            steps {
                sh '''
                    echo "Running unit tests (simulated)"
                    echo "Running security audit (simulated)"
                '''
            }
        }

        stage('Run Container') {
            steps {
                script {
                    sh """
                        echo "Removing old container if it exists..."
                        docker rm -f ${APP_NAME}-app || true

                        echo "Starting container..."
                        docker run -d --name ${APP_NAME}-app -p 3000:80 ${APP_NAME}:${BUILD_VERSION}
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    sh """
                        echo "Waiting for container..."
                        sleep 5

                        docker exec ${APP_NAME}-app curl -f http://localhost

                        echo "Application is healthy"
                    """
                }
            }
        }

        stage('Push to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    script {
                        sh """
                            echo "$PASS" | docker login ${DOCKER_REPO.split('/')[0]} -u $USER --password-stdin

                            echo "Pushing image to Nexus..."
                            docker push ${FULL_IMAGE}:${BUILD_VERSION}
                            docker push ${FULL_IMAGE}:latest
                        """
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Cleaning workspace..."
            cleanWs()
        }

        success {
            echo "Pipeline completed successfully ✅"
        }

        failure {
            echo "Pipeline failed ❌ Check logs"
        }
    }
}
