# Terraform Script

## PreRequisites:
  - Create Pair Keys
  - Create Policies ECR
  - Create User ECR
  - Create Terraform User
  - Create S3 Bucket Terraform
  - Access Key and Access Secret Key of Terraform User

## Deploy

Variables to use in variables pipeline of Azure Devops

- AWS_AK (Access Key)
- AWS_SK (Access Secret Key)

```sh
terraform init
terraform plan
terraform apply --auto-approve
```