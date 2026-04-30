pipeline {
    agent any

    stages {

        stage('Checkout SCM') {
            steps {
                checkout scm
            }
        }

        stage('Inspect Repository') {
            steps {
                echo 'Listing repository contents...'
                sh 'ls -al'
            }
        }

        stage('Terraform Version Check') {
            steps {
                echo 'Checking Terraform...'
                sh 'terraform version || true'
            }
        }

        stage('Terraform Format Check') {
            steps {
                echo 'Checking Terraform formatting...'
                sh 'find . -name "*.tf" -exec terraform fmt -check {} \\; || true'
            }
        }

        stage('Ansible Version Check') {
            steps {
                echo 'Checking Ansible...'
                sh 'ansible --version || true'
            }
        }

        stage('Docker Check') {
            steps {
                echo 'Checking Docker availability...'
                sh 'docker --version || true'
            }
        }

    }

    post {
        always {
            echo 'Cleaning workspace...'
            cleanWs()
        }
        success {
            echo 'DevOps pipeline completed successfully.'
        }
        failure {
            echo 'Pipeline failed. Review console output.'
        }
    }
}
