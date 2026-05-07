pipeline {
    agent any

    environment {
        APP_NAME = "kijanikiosk"
        VERSION = "0.1.0"
        GIT_SHA = "${env.GIT_COMMIT?.take(7) ?: 'local'}"
        IMAGE_TAG = "${VERSION}-${GIT_SHA}"

        // IMPORTANT: Nexus reachable from Jenkins container via docker bridge
        NEXUS_HOST = "172.17.0.1:8082"
        NEXUS_REPO = "kijanikiosk-docker"
        NEXUS_IMAGE = "${NEXUS_HOST}/${NEXUS_REPO}/${APP_NAME}"
    }

    stages {

        stage('Init') {
            steps {
                script {
                    env.GIT_COMMIT = sh(script: "git rev-parse HEAD", returnStdout: true).trim()
                    env.GIT_SHA = env.GIT_COMMIT.take(7)
                    env.IMAGE_TAG = "${VERSION}-${GIT_SHA}"

                    echo "Build version: ${IMAGE_TAG}"
                }
            }
        }

        stage('Lint') {
            steps {
                sh '''
                    echo "Lint stage running..."
                    echo "No lint tool configured (placeholder)"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    echo "Building Docker image..."

                    docker build -t ${APP_NAME}:${IMAGE_TAG} -f app/Dockerfile .

                    docker tag ${APP_NAME}:${IMAGE_TAG} ${NEXUS_IMAGE}:${IMAGE_TAG}
                    docker tag ${APP_NAME}:${IMAGE_TAG} ${NEXUS_IMAGE}:latest
                """
            }
        }

        stage('Verify') {
            parallel {

                stage('Test') {
                    steps {
                        sh '''
                            echo "Running unit tests (simulated)"
                        '''
                    }
                }

                stage('Security Audit') {
                    steps {
                        sh '''
                            echo "Running security audit (simulated)"
                        '''
                    }
                }
            }
        }

        stage('Run Container') {
            steps {
                sh """
                    echo "Stopping old container if exists..."
                    docker rm -f ${APP_NAME}-app || true

                    echo "Starting container..."
                    docker run -d --name ${APP_NAME}-app -p 3000:80 ${APP_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Health Check') {
            steps {
                sh """
                    echo "Waiting for app..."
                    sleep 5

                    curl -f http://localhost:3000

                    echo "Application is healthy"
                """
            }
        }

        stage('Archive') {
            steps {
                sh """
                    echo "Creating artifact..."

                    mkdir -p artifact
                    docker save ${APP_NAME}:${IMAGE_TAG} > artifact/${APP_NAME}-${IMAGE_TAG}.tar
                """

                archiveArtifacts artifacts: 'artifact/*.tar', fingerprint: true
            }
        }

        stage('Push to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {

                    sh """
                        echo "Logging into Nexus..."

                        echo "$PASS" | docker login ${NEXUS_HOST} -u "$USER" --password-stdin

                        echo "Pushing image to Nexus..."

                        docker push ${NEXUS_IMAGE}:${IMAGE_TAG}
                        docker push ${NEXUS_IMAGE}:latest
                    """
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
            echo "Pipeline SUCCESS 🚀"
            echo "Image pushed: ${NEXUS_IMAGE}:${IMAGE_TAG}"
        }

        failure {
            echo "Pipeline FAILED ❌ Check logs"
        }

        changed {
            echo "Pipeline status changed ⚠️"
        }
    }
}
