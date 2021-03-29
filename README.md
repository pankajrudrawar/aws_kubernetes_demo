# Getting Started with Amazon EKS using Terraform**
More resources:

Terraform provider for AWS here

# Login to Amazon

Access your "My Security Credentials" section in your profile. 
Create an access key

aws configure

Default region name: us-east-1
Default output format: json
Terraform CLI

# Get Terraform

curl -o /tmp/terraform.zip -LO https://releases.hashicorp.com/terraform/0.13.1/terraform_0.13.1_linux_amd64.zip
unzip /tmp/terraform.zip
chmod +x terraform && mv terraform /usr/local/bin/
terraform

# Terraform Actions

terraform init

terraform plan

terraform apply

Clean up

terraform destroy
