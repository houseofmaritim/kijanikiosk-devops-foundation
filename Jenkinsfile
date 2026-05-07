pipeline {
    agent any

    environment {
        NEXUS_URL = "localhost:8082"
        NEXUS_REPO = "kijanikiosk-docker"
        IMAGE_NAME = "kijanikiosk"
        IMAGE_TAG = "0.1.0-${GIT_COMMIT}"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/houseofmaritim/kijanikiosk-devops-foundation.git',
                branch: 'feature/week5-ci-pipeline'
            }
        }

        stage('Init') {
            steps {
                script {
                    env.GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    echo "Build version: 0.1.0-${env.GIT_SHA}"
                }
            }
        }

        stage('Lint') {
            steps {
                sh 'echo Lint stage: placeholder'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f app/Dockerfile .

                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} \
                        ${NEXUS_URL}/${NEXUS_REPO}/${IMAGE_NAME}:${IMAGE_TAG}

                    docker tag ${IMAGE_NAME}:${IMAGE_TAG} \
                        ${NEXUS_URL}/${NEXUS_REPO}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Verify') {
            steps {
                sh 'echo Running unit tests (simulated)'
                sh 'echo Running security audit (simulated)'
            }
        }

        stage('Run Container') {
            steps {
                script {
                    sh """
                    echo Cleaning old container if exists...
                    docker rm -f kijanikiosk-app || true

                    echo Starting container...
                    docker run -d --name kijanikiosk-app -p 3000:80 \
                        ${IMAGE_NAME}:${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    sh """
                    echo Waiting for container...
                    sleep 5

                    docker exec kijanikiosk-app curl -f http://localhost || exit 1

                    echo App is healthy
                    """
                }
            }
        }

        stage('Docker Login & Push to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh """
                    echo "$PASS" | docker login ${NEXUS_URL} -u "$USER" --password-stdin

                    echo Pushing image to Nexus...
                    docker push ${NEXUS_URL}/${NEXUS_REPO}/${IMAGE_NAME}:${IMAGE_TAG}
                    docker push ${NEXUS_URL}/${NEXUS_REPO}/${IMAGE_NAME}:latest
                    """
                }
            }
        }
    }

    post {
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
        success {
            echo 'Pipeline completed successfully ✅'
        }
        failure {
            echo 'Pipeline failed ❌ Check logs'
        }
    }
}
