pipeline {
    agent any

    environment {
        IMAGE_NAME = "kijanikiosk"
        VERSION = "0.1.0"
        NEXUS_URL = "http://nexus:8081"
        NEXUS_REPO = "kijanikiosk-repo"
        GIT_SHA = ""
    }

    stages {

        stage('Init') {
            steps {
                script {
                    GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    echo "Build version: ${VERSION}-${GIT_SHA}"
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
                        echo "Cleaning old container if exists..."
                        docker rm -f kijanikiosk-app || true

                        echo "Checking port 3000..."
                        if docker ps --format '{{.Ports}}' | grep 3000; then
                            echo "Port 3000 in use - freeing..."
                            docker ps --filter publish=3000 -q | xargs -r docker stop || true
                            docker ps --filter publish=3000 -q | xargs -r docker rm -f || true
                        fi

                        echo "Starting container..."
                        docker run -d --name kijanikiosk-app -p 3000:80 ${IMAGE_NAME}:${VERSION}-${GIT_SHA}
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

                        for i in \$(seq 1 10); do
                            if docker exec kijanikiosk-app curl -f http://localhost; then
                                echo "App is healthy"
                                exit 0
                            fi
                            echo "Retrying..."
                            sleep 2
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
                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {

                        sh """
                            echo "Packaging artifact..."
                            tar -czf kijanikiosk-${GIT_SHA}.tar.gz app/

                            echo "Uploading to Nexus..."
                            curl -u ${NEXUS_USER}:${NEXUS_PASS} \
                                --upload-file kijanikiosk-${GIT_SHA}.tar.gz \
                                ${NEXUS_URL}/repository/${NEXUS_REPO}/kijanikiosk-${VERSION}-${GIT_SHA}.tar.gz
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
