pipeline {
    agent any

    environment {
        IMAGE_NAME = "kijanikiosk"
        VERSION = "0.1.0"
        NEXUS_URL = "http://172.17.0.3:8081"
        NEXUS_REPO = "kijanikiosk-releases"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Lint') {
            steps {
                sh 'echo "Lint stage: placeholder for code quality checks"'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    env.GIT_SHA = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    sh """
                        docker build -t ${IMAGE_NAME}:${VERSION}-${GIT_SHA} -f app/Dockerfile .
                        docker tag ${IMAGE_NAME}:${VERSION}-${GIT_SHA} ${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Verify') {
            steps {
                script {
                    parallel(
                        "Test": {
                            sh 'echo "Running unit tests (simulated)"'
                        },

                        "Security Audit": {
                            sh 'echo "Running security audit (simulated)"'
                        }
                    )
                }
            }
        }

        stage('Run Container') {
            steps {
                script {
                    sh """
                        docker rm -f kijani-app || true

                        docker run -d \
                            --name kijani-app \
                            -p 3000:80 \
                            ${IMAGE_NAME}:${VERSION}-${GIT_SHA}
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                sh """
                    echo "Waiting for container to be ready..."
                    sleep 5

                    for i in \$(seq 1 15); do

                        if docker exec kijani-app curl -f http://localhost; then
                            exit 0
                        fi

                        echo "Not ready yet... retrying in 3s"
                        sleep 3
                    done

                    echo "Health check failed"
                    exit 1
                """
            }
        }

        stage('Publish to Nexus') {
            steps {
                script {

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'nexus-creds',
                            usernameVariable: 'NEXUS_USER',
                            passwordVariable: 'NEXUS_PASS'
                        )
                    ]) {

                        sh """
                            echo "Creating npm config"

                            echo "registry=${NEXUS_URL}/repository/${NEXUS_REPO}/" > .npmrc
                            echo "username=${NEXUS_USER}" >> .npmrc
                            echo "password=${NEXUS_PASS}" >> .npmrc

                            echo "Packaging artifact"

                            tar -czf ${IMAGE_NAME}-${GIT_SHA}.tar.gz app/

                            echo "Testing Nexus connectivity"

                            curl -v ${NEXUS_URL}

                            echo "Uploading artifact to Nexus"

                            curl -u \$NEXUS_USER:\$NEXUS_PASS \
                                --upload-file ${IMAGE_NAME}-${GIT_SHA}.tar.gz \
                                ${NEXUS_URL}/repository/${NEXUS_REPO}/${IMAGE_NAME}-${VERSION}-${GIT_SHA}.tar.gz

                            rm -f .npmrc
                        """
                    }
                }
            }
        }
    }

    post {

        always {
            echo "Cleaning workspace..."
            cleanWs()
        }

        success {
            echo "Pipeline completed successfully 🎉"
        }

        failure {
            echo "Pipeline failed ❌ Check logs"
        }
    }
}
