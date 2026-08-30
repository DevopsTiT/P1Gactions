# AWS simulator (LocalStack) + Terraform

This folder was missing from your tree earlier — recreate of the LocalStack lab.

## Quick start

```sh
cd terraform/aws-simulate
docker compose up -d
curl -s http://127.0.0.1:4566/_localstack/health
cp terraform.tfvars.example terraform.tfvars
terraform init
terraform plan
terraform apply -auto-approve
terraform output
terraform destroy -auto-approve
docker compose down
```

Requires: Docker, Terraform CLI.
