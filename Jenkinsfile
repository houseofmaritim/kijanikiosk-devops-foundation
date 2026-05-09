pipeline {
    agent any

    environment {
        IMAGE = "spaceofmaritim/kijanikiosk"
        PORT_BLUE = "8081"
        PORT_GREEN = "8082"
        NETWORK = "kijani-net"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build') {
            steps {
                script {
                    env.TAG = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.IMAGE_TAG = "${IMAGE}:${TAG}"
                }

                sh "docker build -t ${IMAGE_TAG} -f app/Dockerfile ."
            }
        }

        stage('Test') {
            steps {
                sh "echo 'Running tests...'"
            }
        }

        stage('Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh """
                        echo $PASS | docker login -u $USER --password-stdin
                        docker push ${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy Blue-Green') {
            steps {
                script {

                    def active = sh(script: "cat kijani_active || echo green", returnStdout: true).trim()
                    def inactive = (active == "green") ? "blue" : "green"

                    def port = (inactive == "blue") ? PORT_BLUE : PORT_GREEN
                    def container = "kijanikiosk-${inactive}"

                    echo "Active: ${active}"
                    echo "Deploying to: ${inactive}"

                    sh """
                        docker rm -f ${container} || true
                        docker run -d --name ${container} --network ${NETWORK} -p ${port}:80 ${IMAGE_TAG}
                    """

                    // health check
                    sh "sleep 5"
                    sh "docker exec ${container} curl -f http://localhost:80 || exit 1"

                    // switch
                    sh """
                        writeFile file: 'kijani_active', text: "${inactive}" 
                        docker exec kijanikiosk-nginx nginx -s reload || true
                        docker exec kijanikiosk-nginx nginx -s reload
                    """

                    echo "Deployment complete. Active: ${inactive}"
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
    }
}
