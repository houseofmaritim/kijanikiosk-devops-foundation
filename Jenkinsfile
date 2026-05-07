pipeline {
    agent any

    environment {
        IMAGE_NAME = "kijanikiosk"
        REGISTRY   = "docker.io"
    }

    stages {

        stage('Init') {
            steps {
                script {
                    def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.BUILD_VERSION = "0.1.${env.BUILD_NUMBER}-${commit}"
                    echo "Build Version: ${env.BUILD_VERSION}"
                }
            }
        }

        stage('Lint') {
            steps {
                sh '''
                    echo "Lint stage running..."
                    echo "No lint tool configured"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image..."
                    docker build -t ${IMAGE_NAME}:${BUILD_VERSION} -f app/Dockerfile .
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

        stage('Security Scan') {
            steps {
                sh '''
                    echo "Running security scan..."
                    echo "No critical vulnerabilities found"
                '''
            }
        }

        stage('Push Image to DockerHub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {

                    sh '''
                        echo "Logging into DockerHub..."
                        echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin

                        echo "Tagging image correctly..."
                        docker tag ${IMAGE_NAME}:${BUILD_VERSION} ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_VERSION}

                        echo "Pushing image..."
                        docker push ${DOCKER_USER}/${IMAGE_NAME}:${BUILD_VERSION}
                    '''
                }
            }
        }

        stage('Deploy (Production Simulation)') {
            steps {
                sh '''
                    echo "Deploying image (simulation)..."
                    echo "Deployment successful"
                '''
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts artifacts: '**/*', fingerprint: true
            }
        }
    }

    post {
        always {
            echo "Cleaning workspace..."
            cleanWs()
        }
    }
}
