cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/39-seq36-batch-combined-terraform"
terraform fmt -check
terraform init
terraform validate
terraform plan
rg -n 'CONFIRM' 39-seq36-batch-combined-terraform.tf
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/39-seq36-batch-combined-terraform" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/39-seq36-batch-combined-terraform" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/39-seq36-batch-combined-terraform/*.md app/Adocs/2026-10-05/39-seq36-batch-combined-terraform/*.txt app/Adocs/2026-10-05/39-seq36-batch-combined-terraform/*.tf app/Adocs/2026-10-05/39-seq36-batch-combined-terraform/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: one Terraform file for the seq 36 Splunk alert batch"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
