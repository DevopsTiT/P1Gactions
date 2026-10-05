cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/43-datalake-batch-result-detector"
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/44-datalake-detector-tf-explain" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/44-datalake-detector-tf-explain" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/44-datalake-detector-tf-explain/*.md app/Adocs/2026-10-05/44-datalake-detector-tf-explain/*.txt
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: explain Datalake batch result detector Terraform"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
