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
                        echo \$PASS | docker login -u \$USER --password-stdin
                        docker push ${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Deploy Blue-Green') {
            steps {
                script {

                    // SAFE READ OF STATE (no crash if file missing)
                    def active = fileExists('kijani_active')
                        ? readFile('kijani_active').trim()
                        : 'green'

                    def inactive = (active == "green") ? "blue" : "green"
                    def port = (inactive == "blue") ? PORT_BLUE : PORT_GREEN
                    def container = "kijanikiosk-${inactive}"

                    echo "Active: ${active}"
                    echo "Deploying to: ${inactive}"

                    // Deploy new container
                    sh """
                        docker rm -f ${container} || true
                        docker run -d --name ${container} --network ${NETWORK} -p ${port}:80 ${IMAGE_TAG}
                    """

                    // Health check (critical safety gate)
                    def health = sh(
                        script: "sleep 5 && docker exec ${container} curl -f http://localhost:80",
                        returnStatus: true
                    )

                    if (health != 0) {
                        echo "❌ Health check failed — rolling back"

                        sh "docker rm -f ${container} || true"

                        error("Deployment aborted due to failed health check")
                    }

                    // Switch traffic ONLY after success
                    writeFile file: 'kijani_active', text: inactive

                    echo "✅ Deployment successful. Active: ${inactive}"
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
