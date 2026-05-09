pipeline {
    agent any

    environment {
        IMAGE = "spaceofmaritim/kijanikiosk"
        PORT_BLUE = "8081"
        PORT_GREEN = "8082"
        NETWORK = "kijani-net"
        STATE_FILE = "kijani_active"
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
                    sh '''
                        echo $PASS | docker login -u $USER --password-stdin
                        docker push $IMAGE_TAG
                    '''
                }
            }
        }

        stage('Deploy Blue-Green') {
            steps {
                script {

                    // SAFE STATE READ (NO FILE CRASH)
                    def active = "green"
                    if (fileExists(env.STATE_FILE)) {
                        active = readFile(env.STATE_FILE).trim()
                    }

                    def inactive = (active == "green") ? "blue" : "green"

                    def port = (inactive == "blue") ? env.PORT_BLUE : env.PORT_GREEN
                    def container = "kijanikiosk-${inactive}"

                    echo "Active environment: ${active}"
                    echo "Deploying to: ${inactive}"

                    // Deploy new version
                    sh """
                        docker rm -f ${container} || true
                        docker run -d --name ${container} --network ${NETWORK} -p ${port}:80 ${IMAGE_TAG}
                    """

                    // Health check
                    sh "sleep 5"
                    sh "docker exec ${container} curl -f http://localhost:80"

                    // SAVE NEW STATE (FIXED WAY)
                    writeFile file: env.STATE_FILE, text: "${inactive}"

                    echo "Deployment complete. Active is now: ${inactive}"
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
