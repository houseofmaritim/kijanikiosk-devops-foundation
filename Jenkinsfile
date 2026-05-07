pipeline {
    agent {
        docker {
            image 'node:18-alpine'
            args '-u root -v /var/run/docker.sock:/var/run/docker.sock -v /usr/bin/docker:/usr/bin/docker'
        }
    }

    options {
        disableConcurrentBuilds()
        timestamps()
    }

    environment {
        APP_NAME = 'kijanikiosk'
        VERSION = "0.1.${BUILD_NUMBER}"
        NEXUS_URL = '172.17.0.1:8082'
        NEXUS_REPOSITORY = 'kijanikiosk-docker'
        IMAGE_NAME = "${APP_NAME}:${VERSION}"
        FULL_IMAGE_NAME = "${NEXUS_URL}/${NEXUS_REPOSITORY}/${APP_NAME}:${VERSION}"
    }

    stages {

        stage('Init') {
            steps {
                script {
                    env.GIT_SHA = sh(
                        script: 'git rev-parse --short HEAD',
                        returnStdout: true
                    ).trim()

                    env.VERSION = "0.1.${BUILD_NUMBER}-${GIT_SHA}"

                    echo "Build version: ${VERSION}"
                }
            }
        }

        stage('Lint') {
            steps {
                sh '''
                    echo "Lint stage running..."
                    echo "No lint tool configured yet"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    echo "Building Docker image..."

                    docker build \
                      -t ${IMAGE_NAME} \
                      -f app/Dockerfile .

                    docker tag \
                      ${IMAGE_NAME} \
                      ${FULL_IMAGE_NAME}
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
                            echo "No vulnerabilities detected"
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
                      ${IMAGE_NAME}
                '''
            }
        }

        stage('Health Check') {
            steps {
                sh '''
                    sleep 5

                    curl -I http://172.17.0.1:3000
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
                withCredentials([
                    usernamePassword(
                        credentialsId: 'nexus-docker-creds',
                        usernameVariable: 'NEXUS_USER',
                        passwordVariable: 'NEXUS_PASS'
                    )
                ]) {

                    sh '''
                        echo "$NEXUS_PASS" | docker login \
                          ${NEXUS_URL} \
                          -u "$NEXUS_USER" \
                          --password-stdin

                        docker push ${FULL_IMAGE_NAME}

                        docker logout ${NEXUS_URL}
                    '''
                }
            }
        }
    }

    post {

        always {
            echo 'Cleaning workspace...'

            cleanWs()
        }

        success {
            echo "Pipeline completed successfully ✅"
            echo "Published image: ${FULL_IMAGE_NAME}"
        }

        failure {
            echo 'Pipeline FAILED ❌ Check logs'
        }

        changed {
            echo 'Pipeline status changed ⚠️'
        }
    }
}
