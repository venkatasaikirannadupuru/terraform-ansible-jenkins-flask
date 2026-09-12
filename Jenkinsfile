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
                withCredentials([
                    string(
                        credentialsId: 'rds-db-password',
                        variable: 'DB_PASSWORD'
                    )
                ]) {
                    sh '''
                        cat > terraform.tfvars <<EOF2
key_name = "linux"
db_password = "$DB_PASSWORD"
EOF2
                        terraform plan
                        rm -f terraform.tfvars
                    '''
                }
            }
        }

        stage('Ansible Ping') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'flask-ec2-ssh-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    )
                ]) {
                    sh '''
                        ansible -i inventory.ini app -m ping \
                        -u "$SSH_USER" \
                        --private-key "$SSH_KEY"
                    '''
                }
            }
        }

        stage('Deploy Flask App') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'flask-ec2-ssh-key',
                        keyFileVariable: 'SSH_KEY',
                        usernameVariable: 'SSH_USER'
                    ),
                    string(
                        credentialsId: 'ansible-vault-password',
                        variable: 'VAULT_PASSWORD'
                    )
                ]) {
                    sh '''
                        VAULT_FILE=$(mktemp)
                        printf '%s' "$VAULT_PASSWORD" > "$VAULT_FILE"
                        chmod 600 "$VAULT_FILE"

                        ansible-playbook \
                        -i inventory.ini \
                        setup.yml \
                        -u "$SSH_USER" \
                        --private-key "$SSH_KEY" \
                        --vault-password-file "$VAULT_FILE" \
                        -e "@vault.yml"

                        ansible-playbook \
                        -i inventory.ini \
                        flask-app/deploy.yml \
                        -u "$SSH_USER" \
                        --private-key "$SSH_KEY"

                        rm -f "$VAULT_FILE"
                    '''
                }
            }
        }
    }
}
