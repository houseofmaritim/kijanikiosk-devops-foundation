pipeline {
    agent any

    environment {
        APP_NAME = "kijani-app"
        IMAGE_NAME = "kijanikiosk"
        VERSION = "0.1.0"
        NEXUS_URL = "http://192.168.0.136:8081"
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
                    def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                    env.GIT_SHA = commit

                    def imageTag = "${IMAGE_NAME}:${VERSION}-${commit}"
                    env.IMAGE_TAG = imageTag

                    sh "docker build -t ${imageTag} -f app/Dockerfile ."
                    sh "docker tag ${imageTag} ${IMAGE_NAME}:latest"
                }
            }
        }

        stage('Verify') {
            steps {
                script {
                    parallel(
                        Test: {
                            sh 'echo "Running unit tests (simulated)"'
                        },
                        'Security Audit': {
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
                        docker rm -f ${APP_NAME} || true
                        docker run -d --name ${APP_NAME} -p 3000:80 ${IMAGE_TAG}
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                sh """
                    echo "Waiting for container to be ready..."
                    sleep 5

                    for i in \$(seq 1 15)
                    do
                        docker exec ${APP_NAME} curl -f http://localhost && exit 0
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
                    withCredentials([usernamePassword(credentialsId: 'nexus-creds', usernameVariable: 'NEXUS_USER', passwordVariable: 'NEXUS_PASS')]) {

                        sh """
                            echo "Creating npm config"
                            echo "registry=${NEXUS_URL}/repository/${NEXUS_REPO}/" > .npmrc
                            echo "username=${NEXUS_USER}" >> .npmrc
                            echo "password=${NEXUS_PASS}" >> .npmrc

                            echo "Packaging artifact"
                            tar -czf ${IMAGE_NAME}-${GIT_SHA}.tar.gz app/

                            echo "Uploading to Nexus (simulated upload step)"
                            curl -u $NEXUS_USER:$NEXUS_PASS \
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
