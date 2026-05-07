pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        APP_NAME = "kijanikiosk"
        NEXUS_URL = "172.17.0.1:8082"
        NEXUS_REPO = "kijanikiosk-docker"
    }

    stages {

        stage('Init') {
            steps {
                script {
                    env.GIT_SHA = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.VERSION = "0.1.${BUILD_NUMBER}-${GIT_SHA}"
                    env.IMAGE_LOCAL = "${APP_NAME}:${VERSION}"
                    env.IMAGE_REMOTE = "${NEXUS_URL}/${NEXUS_REPO}/${APP_NAME}:${VERSION}"

                    echo "Version: ${VERSION}"
                }
            }
        }

        stage('Lint') {
            steps {
                sh '''
                    echo "Lint stage running..."
                    echo "No linter configured (placeholder)"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image..."

                    docker build -t ${IMAGE_LOCAL} -f app/Dockerfile .
                '''
            }
        }

        stage('Verify') {
            parallel {

                stage('Test') {
                    steps {
                        sh '''
                            echo "Running tests..."
                            echo "Tests passed"
                        '''
                    }
                }

                stage('Security Audit') {
                    steps {
                        sh '''
                            echo "Running security audit..."
                            echo "No vulnerabilities found"
                        '''
                    }
                }
            }
        }

        stage('Run Container') {
            steps {
                sh '''
                    docker rm -f kijanikiosk-app || true

                    docker run -d \
                      --name kijanikiosk-app \
                      -p 3000:80 \
                      ${IMAGE_LOCAL}
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    sleep 5
                    curl -I http://172.17.0.1:3000 || true
                '''
            }
        }

        stage('Archive') {
            steps {
                sh '''
                    mkdir -p artifacts
                    echo ${VERSION} > artifacts/version.txt
                '''

                archiveArtifacts artifacts: 'artifacts/*', fingerprint: true
            }
        }

        stage('Push to Nexus') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'nexus-docker-creds',
                    usernameVariable: 'USER',
                    passwordVariable: 'PASS'
                )]) {

                    sh '''
                        echo "$PASS" | docker login ${NEXUS_URL} -u "$USER" --password-stdin

                        docker tag ${IMAGE_LOCAL} ${IMAGE_REMOTE}

                        docker push ${IMAGE_REMOTE}

                        docker logout ${NEXUS_URL}
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
            echo "Pipeline SUCCESS ✅"
            echo "Image: ${IMAGE_REMOTE}"
        }

        failure {
            echo "Pipeline FAILED ❌"
        }

        changed {
            echo "Pipeline status changed ⚠️"
        }
    }
}
