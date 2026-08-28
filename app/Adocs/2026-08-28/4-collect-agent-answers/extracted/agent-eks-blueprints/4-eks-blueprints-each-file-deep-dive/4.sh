# EKS Blueprints file-by-file — review before running
ls /Users/k/Learnings/AIProject/CursorFiles/Daily\ Files/2026-07-30/4-eks-blueprints-each-file-deep-dive
ls /Users/k/Learnings/AIProject/CursorFiles/Daily\ Files/2026-07-30/4-eks-blueprints-each-file-deep-dive/patterns
ls /Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main
ls /Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main/patterns
ls /Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main/docs
ls /Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main/.github/workflows
cd /Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main/patterns/karpenter
terraform init
terraform apply -target="module.vpc" -auto-approve
terraform apply -target="module.eks" -auto-approve
terraform apply -auto-approve
terraform output -raw configure_kubectl
kubectl get nodes
cd /Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main/patterns/gitops/getting-started-argocd
cd /Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main/patterns/fully-private-cluster
cd /Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main/patterns/blue-green-upgrade
find /Users/k/Codes/GithubProjects/Terraform/terraform-aws-eks-blueprints-main/patterns -maxdepth 2 -type f -name '*.tf' | sort
