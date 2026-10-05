cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/40-seq35-batch-combined-terraform/all-34-35-36"
terraform init
terraform validate
terraform plan
cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/40-seq35-batch-combined-terraform/batch-35"
terraform init
terraform validate
terraform plan
rg -n 'arrayMovingMax|CONFIRM' "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/40-seq35-batch-combined-terraform"
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/40-seq35-batch-combined-terraform" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/40-seq35-batch-combined-terraform" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/40-seq35-batch-combined-terraform/*.md app/Adocs/2026-10-05/40-seq35-batch-combined-terraform/*.txt app/Adocs/2026-10-05/40-seq35-batch-combined-terraform/*.dql app/Adocs/2026-10-05/40-seq35-batch-combined-terraform/batch-35/*.tf app/Adocs/2026-10-05/40-seq35-batch-combined-terraform/all-34-35-36/*.tf
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: combined Terraform for seq 35 batch and deduplicated Jenkins batches 34-36"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
