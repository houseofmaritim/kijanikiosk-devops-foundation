pipeline {
    agent any

    environment {
        IMAGE_NAME = "kijanikiosk"
        VERSION = "0.1.0"
        GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()

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
                    sh """
                        docker build -t ${IMAGE_NAME}:${VERSION}-${GIT_SHA} -f app/Dockerfile .
                        docker tag ${IMAGE_NAME}:${VERSION}-${GIT_SHA} ${IMAGE_NAME}:latest
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
                script {
                    sh """
                        docker rm -f ${IMAGE_NAME}-app || true
                        docker run -d --name ${IMAGE_NAME}-app -p 3000:80 ${IMAGE_NAME}:${VERSION}-${GIT_SHA}
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    sh """
                        echo "Waiting for container..."
                        sleep 5

                        for i in \$(seq 1 15); do
                            if docker exec ${IMAGE_NAME}-app curl -f http://localhost; then
                                echo "App is healthy"
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
        }

        stage('Publish to Nexus') {
            steps {
                script {

                    // Get Nexus container IP safely
                    def nexusIp = sh(
                        script: "docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' nexus",
                        returnStdout: true
                    ).trim()

                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {

                        sh """
                            echo "Packaging artifact..."
                            tar -czf ${IMAGE_NAME}-${GIT_SHA}.tar.gz app/

                            echo "Uploading artifact to Nexus at ${nexusIp}"

                            curl -u ${NEXUS_USER}:${NEXUS_PASS} \
                                --upload-file ${IMAGE_NAME}-${GIT_SHA}.tar.gz \
                                http://${nexusIp}:8081/repository/${NEXUS_REPO}/${IMAGE_NAME}-${VERSION}-${GIT_SHA}.tar.gz
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
