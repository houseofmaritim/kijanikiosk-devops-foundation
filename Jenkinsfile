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
                    def imageTag = "kijanikiosk:${commit}"

                    env.IMAGE_TAG = imageTag

                    sh "docker build -t ${imageTag} -f app/Dockerfile ."
                    sh "docker tag ${imageTag} kijanikiosk:latest"
                }
            }
        }

        stage('List Docker Images') {
            steps {
                sh 'docker images | grep kijanikiosk || true'
            }
        }

        stage('Run Container') {
            steps {
                script {
                    sh """
                    docker rm -f kijani-app || true
                    docker run -d --name kijani-app -p 3000:80 ${env.IMAGE_TAG}
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                sh """
                echo "Waiting for application to start..."

                sleep 10

                for i in \$(seq 1 15)
                do
                    curl -f http://localhost:3000 && exit 0
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
            echo 'Pipeline completed successfully 🎉'
        }
        failure {
            echo 'Pipeline failed ❌ Check logs'
        }
    }
}
