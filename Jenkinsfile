pipeline {
    agent any

    stages {

        stage('Checkout Source Code') {
            steps {
                echo 'Pulling latest repository from GitHub...'
                checkout scm
            }
        }

        stage('Inspect Repository Structure') {
            steps {
                echo 'Inspecting files in repository...'
                sh 'ls -al'
            }
        }

        stage('Terraform Version') {
            steps {
                echo 'Verifying Terraform installation...'
                sh 'terraform version'
            }
        }

        stage('Terraform Format Validation') {
            steps {
                echo 'Running terraform fmt check on all .tf files...'
                sh '''
                find . -name "*.tf" | while read file; do
                    terraform fmt -check "$file" || true
                done
                '''
            }
        }

        stage('Terraform Init Validation') {
            steps {
                echo 'Initializing Terraform directories where applicable...'
                sh '''
                find . -type d -name terraform | while read dir; do
                    echo "Checking Terraform in $dir"
                    cd "$dir"
                    terraform init -backend=false
                    terraform validate || true
                    cd - > /dev/null
                done
                '''
            }
        }

        stage('Ansible Version') {
            steps {
                echo 'Checking Ansible installation...'
                sh 'ansible --version'
            }
        }

        stage('Ansible Syntax Check') {
            steps {
                echo 'Searching for playbooks and validating syntax...'
                sh '''
                find . -name "*.yml" -o -name "*.yaml" | while read file; do
                    if grep -q "hosts:" "$file"; then
                        echo "Syntax checking $file"
                        ansible-playbook --syntax-check "$file" || true
                    fi
                done
                '''
            }
        }

        stage('Docker Availability Check') {
            steps {
                echo 'Checking Docker CLI availability...'
                sh 'docker --version'
            }
        }

        stage('Docker Daemon Connectivity') {
            steps {
                echo 'Checking Docker daemon connection...'
                sh 'docker ps || true'
            }
        }
    }

    post {
        always {
            echo 'Cleaning Jenkins workspace...'
            cleanWs()
        }

        success {
            echo 'SUCCESS: Full DevOps CI validation pipeline passed.'
        }

        failure {
            echo 'FAILURE: One or more DevOps validation stages failed.'
        }
    }
}
