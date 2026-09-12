stage('Terraform Plan') {
    steps {
        withCredentials([
            string(credentialsId: 'rds-db-password', variable: 'DB_PASSWORD')
        ]) {
            sh '''
                cat > terraform.tfvars <<EOF
key_name    = "linux"
db_password = "$DB_PASSWORD"
EOF

                terraform plan
                rm -f terraform.tfvars
            '''
        }
    }
}