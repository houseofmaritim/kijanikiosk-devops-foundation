pipeline {
    agent any

    environment {
        APP_NAME = "kijani-app"
        IMAGE_NAME = "kijanikiosk"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    def imageTag = "${IMAGE_NAME}:${commit}"

                    env.IMAGE_TAG = imageTag

                    sh "docker build -t ${imageTag} -f app/Dockerfile ."
                    sh "docker tag ${imageTag} ${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Run Container') {
            steps {
                script {
                    sh """
                        docker rm -f ${APP_NAME} || true
                        docker run -d --name ${APP_NAME} -p 3000:80 ${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                sh """
                    echo "Waiting for container to be ready..."
                    sleep 5

                    for i in \$(seq 1 15)
                    do
                        docker exec ${APP_NAME} curl -f http://localhost && exit 0
                        echo "Not ready yet... retrying in 3s"
                        sleep 3
                    done

                    echo "Health check failed"
                    exit 1
                """
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully 🎉"
        }
        failure {
            echo "Pipeline failed ❌ Check logs"
        }
    }
}
