pipeline {
    agent any

    environment {
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
                    // Build ONLY the app Dockerfile (NOT root Dockerfile)
                    sh """
                        docker build -t ${IMAGE_NAME}:latest -f app/Dockerfile .
                    """
                }
            }
        }

        stage('List Docker Images') {
            steps {
                sh "docker images"
            }
        }

        stage('Run Container') {
            steps {
                script {
                    // Stop old container if it exists (ignore errors)
                    sh """
                        docker rm -f kijani-app || true
                    """

                    // Run new container
                    sh """
                        docker run -d --name kijani-app -p 3000:80 ${IMAGE_NAME}:latest
                    """
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully 🎉'
        }
        failure {
            echo 'Pipeline failed ❌ Check logs'
        }
    }
}
