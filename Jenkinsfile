pipeline {
    agent {
        docker {
            image 'node:18-bullseye'
            args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        APP_NAME = "kijanikiosk"
        VERSION = "0.1.0-${GIT_COMMIT.take(7)}"
        IMAGE_NAME = "kijanikiosk:${VERSION}"

        // IMPORTANT: Nexus on host (your confirmed working setup)
        NEXUS_HOST = "172.17.0.1"
        NEXUS_PORT = "8082"
        NEXUS_REPO = "kijanikiosk-docker"
        NEXUS_URL = "http://${NEXUS_HOST}:${NEXUS_PORT}"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        stage('Init') {
            steps {
                script {
                    env.VERSION = "0.1.0-${sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()}"
                    echo "Build version: ${env.VERSION}"
                }
            }
        }

        stage('Lint') {
            steps {
                sh 'echo "Lint stage running..."'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME} -f app/Dockerfile .
                    docker tag ${IMAGE_NAME} ${NEXUS_HOST}:${NEXUS_PORT}/${NEXUS_REPO}/${APP_NAME}:${VERSION}
                    docker tag ${IMAGE_NAME} ${NEXUS_HOST}:${NEXUS_PORT}/${NEXUS_REPO}/${APP_NAME}:latest
                """
            }
        }

        stage('Verify') {
            parallel {
                stage('Test') {
                    steps {
                        sh 'echo "Running unit tests (simulated)"'
                    }
                }
                stage('Security Audit') {
                    steps {
                        sh 'echo "Running security audit (simulated)"'
                    }
                }
            }
        }

        stage('Run Container') {
            steps {
                sh """
                    docker rm -f ${APP_NAME}-app || true
                    docker run -d --name ${APP_NAME}-app -p 3000:80 ${IMAGE_NAME}
                """
            }
        }

        stage('Health Check') {
            steps {
                sh """
                    echo "Waiting for container..."
                    sleep 5
                    docker exec ${APP_NAME}-app curl -f http://localhost
                """
            }
        }

        stage('Archive') {
            steps {
                sh """
                    mkdir -p artifacts
                    docker save ${IMAGE_NAME} > artifacts/${APP_NAME}-${VERSION}.tar
                """
                archiveArtifacts artifacts: 'artifacts/*.tar', fingerprint: true
            }
        }

        stage('Push to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh """
                        echo "$PASS" | docker login ${NEXUS_HOST}:${NEXUS_PORT} -u "$USER" --password-stdin

                        echo "Pushing image to Nexus..."
                        docker push ${NEXUS_HOST}:${NEXUS_PORT}/${NEXUS_REPO}/${APP_NAME}:${VERSION}
                        docker push ${NEXUS_HOST}:${NEXUS_PORT}/${NEXUS_REPO}/${APP_NAME}:latest
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
            echo "Pipeline succeeded ✔ Image pushed: ${NEXUS_URL}"
        }

        failure {
            echo "Pipeline failed ❌ Check logs"
        }

        changed {
            echo "Pipeline status changed ⚠️"
        }
    }
}
