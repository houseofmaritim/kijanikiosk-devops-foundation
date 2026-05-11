pipeline {
    agent any

    environment {
        IMAGE_NAME = "kk-payments"
        NAMESPACE = "kk-payments"
        IMAGE_TAG = "${BUILD_NUMBER}"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'feature/week8-container-delivery-pipeline',
                    url: 'https://github.com/houseofmaritim/kijanikiosk-devops-foundation.git'
            }
        }

        stage('Verify Docker Access') {
            steps {
                sh 'docker version'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                docker build \
                -f Dockerfile.production \
                -t $IMAGE_NAME:$IMAGE_TAG .
                """
            }
        }

        stage('Verify Kubernetes Access') {
            steps {
                sh 'kubectl version --client'
                sh 'kubectl get nodes'
            }
        }

        stage('Verify Deployment Exists') {
            steps {
                sh """
                kubectl get deployment $IMAGE_NAME \
                -n $NAMESPACE
                """
            }
        }

        stage('Deploy Updated Image') {
            steps {
                sh """
                kubectl set image deployment/$IMAGE_NAME \
                $IMAGE_NAME=$IMAGE_NAME:$IMAGE_TAG \
                -n $NAMESPACE
                """
            }
        }

        stage('Verify Rollout') {
            steps {
                sh """
                kubectl rollout status deployment/$IMAGE_NAME \
                -n $NAMESPACE --timeout=120s
                """
            }
        }

        stage('Cleanup Dangling Images') {
            steps {
                sh 'docker image prune -f'
            }
        }
    }

    post {

        success {
            echo 'Week 8 container delivery pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Review console output.'
        }

        always {
            sh 'docker images | head'
        }
    }
}
