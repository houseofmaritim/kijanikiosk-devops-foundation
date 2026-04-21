pipeline {
    agent {
        docker {
            image 'node:18-alpine'
            args '--network=host'
        }
    }

    environment {
        NEXUS_URL = 'http://<YOUR_VM_IP>:8081'
        NEXUS_REPO = 'npm-releases'
        PACKAGE_NAME = 'kijanikiosk-payments'
    }

    stages {
        stage('Lint') {
            steps {
                sh 'npm install'
                sh 'npm run lint'
            }
        }

        stage('Build') {
            steps {
                sh 'npm run build'
            }
        }

        stage('Verify') {
            parallel {
                stage('Test') {
                    steps {
                        sh 'npm test'
                    }
                }
                stage('Security Audit') {
                    steps {
                        sh 'npm audit --audit-level=high'
                    }
                }
            }
        }

        stage('Archive') {
            steps {
                archiveArtifacts artifacts: '**/dist/**', fingerprint: true
            }
        }

        stage('Publish') {
            steps {
                withCredentials([string(credentialsId: 'nexus-npm-token', variable: 'NPM_TOKEN')]) {
                    sh '''
                    VERSION=$(node -p "require('./package.json').version")
                    GIT_SHA=$(git rev-parse --short HEAD)
                    NEW_VERSION="${VERSION}-${GIT_SHA}"
                    npm version $NEW_VERSION --no-git-tag-version

                    echo "//$(echo $NEXUS_URL | sed 's|http://||')/repository/$NEXUS_REPO/:_authToken=$NPM_TOKEN" > .npmrc
                    npm publish --registry $NEXUS_URL/repository/$NEXUS_REPO/
                    rm -f .npmrc
                    '''
                }
            }
        }
    }

    post {
        always {
            cleanWs()
        }
        success {
            echo "Build succeeded. Artifact published to Nexus."
        }
        failure {
            echo "Build failed. Check logs for details."
        }
        changed {
            echo "Build status changed."
        }
    }
}
