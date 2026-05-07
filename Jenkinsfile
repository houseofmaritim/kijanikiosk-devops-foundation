pipeline {
    agent {
        docker {
            image 'node:18-alpine'
            args '-u root:root -v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        IMAGE_NAME = "kijanikiosk"
        NEXUS_URL = "http://172.17.0.1:8082"
        NEXUS_REPO = "kijanikiosk-docker"
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        stage('Init') {
            steps {
                script {
                    env.GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.VERSION = "0.1.0-${env.GIT_SHA}"
                    echo "Build version: ${env.VERSION}"
                }
            }
        }

        stage('Lint') {
            steps {
                sh 'echo "Lint stage: placeholder"'
            }
        }

        stage('Build Docker Image') {
            steps {
                script {
                    sh """
                        docker build -t ${IMAGE_NAME}:${VERSION} -f app/Dockerfile .
                        docker tag ${IMAGE_NAME}:${VERSION} ${NEXUS_URL}/${NEXUS_REPO}/${IMAGE_NAME}:${VERSION}
                        docker tag ${IMAGE_NAME}:${VERSION} ${NEXUS_URL}/${NEXUS_REPO}/${IMAGE_NAME}:latest
                    """
                }
            }
        }

        stage('Verify') {
            parallel {

                stage('Test') {
                    steps {
                        sh 'echo "Running unit tests (simulated)"'
                    }
                }

                stage('Security Audit') {
                    steps {
                        sh 'echo "Running security audit (simulated)"'
                    }
                }
            }
        }

        stage('Run Container') {
            steps {
                sh """
                    docker rm -f kijanikiosk-app || true
                    docker run -d --name kijanikiosk-app -p 3000:80 ${IMAGE_NAME}:${VERSION}
                """
            }
        }

        stage('Health Check') {
            steps {
                sh """
                    sleep 5
                    docker exec kijanikiosk-app curl -f http://localhost || exit 1
                    echo "Application is healthy"
                """
            }
        }

        stage('Archive') {
            steps {
                sh """
                    mkdir -p artifacts
                    echo "${VERSION}" > artifacts/version.txt
                    docker save ${IMAGE_NAME}:${VERSION} -o artifacts/image.tar
                """
                archiveArtifacts artifacts: 'artifacts/**', fingerprint: true
            }
        }

        stage('Push to Nexus') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'USER', passwordVariable: 'PASS')]) {
                    sh """
                        echo \$PASS | docker login ${NEXUS_URL} -u \$USER --password-stdin

                        docker push ${NEXUS_URL}/${NEXUS_REPO}/${IMAGE_NAME}:${VERSION}
                        docker push ${NEXUS_URL}/${NEXUS_REPO}/${IMAGE_NAME}:latest
                    """
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
            echo "Pipeline completed successfully ✅"
            echo "Artifact version: ${VERSION}"
        }

        failure {
            echo "Pipeline failed ❌ Check logs"
        }

        changed {
            echo "Pipeline status changed ⚠️"
        }
    }
}
