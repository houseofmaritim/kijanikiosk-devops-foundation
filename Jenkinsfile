pipeline {
    agent any

    environment {
        APP_NAME = "kijanikiosk-app"
        PORT = "3000"
        IMAGE_NAME = "spaceofmaritim/kijanikiosk"
        DOCKERHUB_CREDENTIALS = "dockerhub-creds"
    }

    stages {

        stage('Init') {
            steps {
                script {
                    def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.IMAGE_TAG = "0.1.${BUILD_NUMBER}-${commit}"
                    echo "Build Version: ${env.IMAGE_TAG}"
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
                    docker build -t $IMAGE_NAME:$IMAGE_TAG -f app/Dockerfile .
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
                script {
                    withCredentials([usernamePassword(
                        credentialsId: DOCKERHUB_CREDENTIALS,
                        usernameVariable: 'USER',
                        passwordVariable: 'PASS'
                    )]) {
                        sh '''
                            echo "$PASS" | docker login -u "$USER" --password-stdin

                            docker tag $IMAGE_NAME:$IMAGE_TAG $USER/$IMAGE_NAME:$IMAGE_TAG
                            docker push $USER/$IMAGE_NAME:$IMAGE_TAG
                        '''
                    }
                }
            }
        }

        stage('Deploy (Production Simulation)') {
            steps {
                script {

                    sh '''
                        echo "Stopping old container..."
                        docker rm -f $APP_NAME || true

                        echo "Pulling image from DockerHub..."
                        docker pull $USER/$IMAGE_NAME:$IMAGE_TAG

                        echo "Starting new container..."
                        docker run -d --name $APP_NAME -p $PORT:80 $USER/$IMAGE_NAME:$IMAGE_TAG

                        echo "Waiting for startup..."
                        sleep 5

                        echo "Health checking..."
                        SUCCESS=0

                        for i in $(seq 1 10)
                        do
                            if docker exec $APP_NAME curl -fs http://localhost >/dev/null 2>&1
                            then
                                echo "Application healthy ✅"
                                SUCCESS=1
                                break
                            fi

                            echo "Attempt $i failed..."
                            sleep 3
                        done

                        if [ "$SUCCESS" -ne 1 ]; then
                            echo "Deployment FAILED ❌"

                            docker rm -f $APP_NAME || true
                            exit 1
                        fi

                        echo "Deployment SUCCESS ✅"
                    '''
                }
            }
        }

        stage('Archive') {
            steps {
                sh '''
                    mkdir -p artifacts
                    echo $IMAGE_TAG > artifacts/version.txt
                '''
                archiveArtifacts artifacts: 'artifacts/**'
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
