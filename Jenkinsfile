pipeline {
    agent any

    environment {
        IMAGE_NAME = "kk-payments"
        NAMESPACE = "kk-payments"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'feature/week8-container-delivery',
                    url: 'https://github.com/houseofmaritim/kijanikiosk-devops-foundation.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t $IMAGE_NAME:${BUILD_NUMBER} -f Dockerfile.production ."
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh """
                kubectl set image deployment/$IMAGE_NAME \
                $IMAGE_NAME=$IMAGE_NAME:${BUILD_NUMBER} \
                -n $NAMESPACE
                """
            }
        }

        stage('Verify Deployment') {
            steps {
                sh "kubectl rollout status deployment/$IMAGE_NAME -n $NAMESPACE"
            }
        }
    }
}
