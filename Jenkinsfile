pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh 'docker build -t kijanikiosk:latest -f app/Dockerfile .'
                }
            }
        }

        stage('List Docker Images') {
            steps {
                script {
                    sh 'docker images'
                }
            }
        }

        stage('Run Container') {
            steps {
                script {
                    // Remove old container if it exists
                    sh '''
                        docker rm -f kijani-app || true
                        docker run -d --name kijani-app -p 3000:80 kijanikiosk:latest
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    sh '''
                        echo "Waiting for app to start..."
                        sleep 5

                        echo "Running health check..."

                        docker run --rm \
                            --network container:kijani-app \
                            curlimages/curl:latest \
                            curl -f http://localhost:80
                    '''
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
