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
                    def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.IMAGE_TAG = "kijanikiosk:${commit}"

                    sh "docker build -t ${IMAGE_TAG} -f app/Dockerfile ."
                    sh "docker tag ${IMAGE_TAG} kijanikiosk:latest"
                }
            }
        }

        stage('List Docker Images') {
            steps {
                sh 'docker images | grep kijanikiosk'
            }
        }

        stage('Run Container') {
            steps {
                script {
                    sh '''
                    docker rm -f kijani-app || true
                    docker run -d --name kijani-app -p 3000:80 kijanikiosk:latest
                    '''
                }
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                sleep 5
                curl -f http://localhost:3000 || exit 1
                '''
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
