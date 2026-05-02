pipeline {
    agent any

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Verify Files') {
            steps {
                sh 'echo "Repository checked successfully"'
                sh 'ls -la'
            }
        }

        stage('Docker Build Test') {
            steps {
                sh 'docker --version'
            }
        }
    }
}
