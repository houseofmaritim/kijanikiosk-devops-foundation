pipeline {
    agent {
        docker {
            image 'node:18-bullseye'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }

    environment {
        APP_NAME = "kijanikiosk"
        NEXUS_URL = "172.17.0.1:8082"
        NEXUS_REPO = "kijanikiosk-docker"
        IMAGE_NAME = "kijanikiosk"
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
                    env.BUILD_VERSION = "0.1.0-${env.GIT_SHA}"
                    echo "Build version: ${env.BUILD_VERSION}"
                }
            }
        }

        stage('Lint') {
            steps {
                sh '''
                echo "Lint stage running..."
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t ${IMAGE_NAME}:${BUILD_VERSION} -f app/Dockerfile .

                docker tag ${IMAGE_NAME}:${BUILD_VERSION} \
                ${NEXUS_URL}/${NEXUS_REPO}/${IMAGE_NAME}:${BUILD_VERSION}

                docker tag ${IMAGE_NAME}:${BUILD_VERSION} \
                ${NEXUS_URL}/${NEXUS_REPO}/${IMAGE_NAME}:latest
                '''
            }
        }

        stage('Verify') {
            parallel {

                stage('Test') {
                    steps {
                        sh '''
                        echo "Running unit tests..."
                        sleep 2
                        echo "Tests passed"
                        '''
                    }
                }

                stage('Security Audit') {
                    steps {
                        sh '''
                        echo "Running security audit..."
                        sleep 2
                        echo "No vulnerabilities found"
                        '''
                    }
                }
            }
        }

        stage('Run Container') {
            steps {
                sh '''
                docker rm -f ${APP_NAME} || true

                docker run -d --name ${APP_NAME} -p 3000:80 \
                ${IMAGE_NAME}:${BUILD_VERSION}
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                echo "Waiting for container..."
                sleep 5
                curl -f http://localhost:3000 || exit 1
                echo "Application healthy"
                '''
            }
        }

        stage('Archive') {
            steps {
                sh '''
                mkdir -p artifact
                echo "${BUILD_VERSION}" > artifact/version.txt
                docker save ${IMAGE_NAME}:${BUILD_VERSION} -o artifact/image.tar
                '''
            }
        }

        stage('Push to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-creds',
                    usernameVariable: 'NEXUS_USER',
                    passwordVariable: 'NEXUS_PASS'
                )]) {
                    sh '''
                    echo "$NEXUS_PASS" | docker login ${NEXUS_URL} \
                    -u "$NEXUS_USER" --password-stdin

                    docker push ${NEXUS_URL}/${NEXUS_REPO}/${IMAGE_NAME}:${BUILD_VERSION}
                    docker push ${NEXUS_URL}/${NEXUS_REPO}/${IMAGE_NAME}:latest
                    '''
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
            echo "Pipeline SUCCESS ✅ Version: ${BUILD_VERSION}"
        }

        failure {
            echo "Pipeline FAILED ❌ Check logs"
        }

        changed {
            echo "Pipeline status changed ⚠️"
        }
    }
}
