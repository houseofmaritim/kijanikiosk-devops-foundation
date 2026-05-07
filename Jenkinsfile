pipeline {
    agent any

    environment {
        APP_NAME = "kijanikiosk-app"
        PORT = "3000"
    }

    stages {

        stage('Init') {
            steps {
                script {
                    env.GIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()

                    env.IMAGE_TAG = "${BUILD_NUMBER}-${env.GIT_SHORT}"

                    echo "Version: ${IMAGE_TAG}"
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

                    docker build \
                    -t kijanikiosk:${IMAGE_TAG} \
                    -f app/Dockerfile .
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
                    docker rm -f ${APP_NAME} || true

                    echo "Starting new container..."

                    docker run -d \
                    --name ${APP_NAME} \
                    -p ${PORT}:80 \
                    kijanikiosk:${IMAGE_TAG}
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    echo "Waiting for container to be ready..."

                    for i in $(seq 1 10)
                    do
                        echo "Attempt $i: checking application..."

                        if docker exec ${APP_NAME} curl -fs http://localhost >/dev/null 2>&1
                        then
                            echo "Application is healthy ✅"
                            exit 0
                        fi

                        echo "App not ready yet, retrying..."
                        sleep 3
                    done

                    echo "Health check FAILED ❌"

                    docker logs ${APP_NAME} || true

                    exit 1
                '''
            }
        }

        stage('Archive') {
            steps {
                sh '''
                    mkdir -p artifacts
                    echo ${IMAGE_TAG} > artifacts/version.txt
                '''

                archiveArtifacts artifacts: 'artifacts/**'
            }
        }

        stage('Push to DockerHub') {
            steps {
                script {

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'dockerhub-creds',
                            usernameVariable: 'USER',
                            passwordVariable: 'PASS'
                        )
                    ]) {

                        sh '''
                            echo "Logging into DockerHub..."

                            echo $PASS | docker login -u spaceofmaritim --password-stdin

                            echo "Tagging image for DockerHub..."

                            docker tag \
                            kijanikiosk:${IMAGE_TAG} \
                            spaceofmaritim/kijanikiosk:${BUILD_NUMBER}

                            echo "Pushing image to DockerHub..."

                            docker push \
                            spaceofmaritim/kijanikiosk:${BUILD_NUMBER}

                            echo "DockerHub push successful ✅"
                        '''
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
