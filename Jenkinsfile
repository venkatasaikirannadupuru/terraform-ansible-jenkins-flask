pipeline {
    agent any

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan'
            }
        }

        stage('Ansible Ping') {
            steps {
                sh 'ansible -i inventory.ini app -m ping --private-key /home/ec2-user/linux.pem'
            }
        }

        stage('Deploy Flask App') {
            steps {
                sh '''
                    ansible-playbook \
                    -i inventory.ini \
                    setup.yml \
                    --private-key /home/ec2-user/linux.pem
                '''

                sh '''
                    ansible-playbook \
                    -i inventory.ini \
                    flask-app/deploy.yml \
                    --private-key /home/ec2-user/linux.pem
                '''
            }
        }
    }
}