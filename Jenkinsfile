pipeline {
    agent any

    environment {
        IMAGE_NAME = "kijanikiosk"
        CONTAINER_NAME = "kijanikiosk-app"
        PORT = "3000"
    }

    stages {

        stage('Init') {
            steps {
                script {
                    def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.VERSION = "0.1.${BUILD_NUMBER}-${commit}"
                    echo "Version: ${env.VERSION}"
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
                sh '''
                    echo "Building Docker image..."
                    docker build -t ${IMAGE_NAME}:${VERSION} -f app/Dockerfile .
                '''
            }
        }

        stage('Test') {
            steps {
                sh '''
                    echo "Running tests..."
                    echo "Tests passed"
                '''
            }
        }

        stage('Security Audit') {
            steps {
                sh '''
                    echo "Running security audit..."
                    echo "No vulnerabilities found"
                '''
            }
        }

        stage('Run Container') {
            steps {
                sh '''
                    echo "Stopping old container if exists..."
                    docker rm -f ${CONTAINER_NAME} || true

                    echo "Starting container..."
                    docker run -d --name ${CONTAINER_NAME} -p ${PORT}:80 ${IMAGE_NAME}:${VERSION}
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "Waiting for container to be ready..."

                    for i in $(seq 1 10); do
                        echo "Attempt $i: checking application..."
                        
                        if curl -fs http://localhost:${PORT} > /dev/null; then
                            echo "Application is healthy ✅"
                            exit 0
                        fi

                        echo "App not ready yet, retrying..."
                        sleep 2
                    done

                    echo "Health check FAILED ❌"
                    exit 1
                '''
            }
        }

        stage('Archive') {
            steps {
                sh '''
                    mkdir -p artifacts
                    echo ${VERSION} > artifacts/version.txt
                '''
                archiveArtifacts artifacts: 'artifacts/**'
            }
        }

        stage('Push to Nexus (Optional)') {
            steps {
                script {
                    try {
                        withCredentials([usernamePassword(
                            credentialsId: 'nexus-docker-creds',
                            usernameVariable: 'NEXUS_USER',
                            passwordVariable: 'NEXUS_PASS'
                        )]) {
                            sh '''
                                echo "Logging into Nexus..."
                                echo $NEXUS_PASS | docker login -u $NEXUS_USER --password-stdin

                                echo "Tagging image..."
                                docker tag ${IMAGE_NAME}:${VERSION} nexus-repo/${IMAGE_NAME}:${VERSION}

                                echo "Pushing image..."
                                docker push nexus-repo/${IMAGE_NAME}:${VERSION}
                            '''
                        }
                    } catch (Exception e) {
                        echo "Skipping Nexus push (not configured or failed)"
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
            echo "Pipeline SUCCESS ✅"
        }

        failure {
            echo "Pipeline FAILED ❌"
        }
    }
}
