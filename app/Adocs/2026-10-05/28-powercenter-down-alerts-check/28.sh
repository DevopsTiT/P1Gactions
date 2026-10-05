cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/28-powercenter-down-alerts-check"
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/28-powercenter-down-alerts-check" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/28-powercenter-down-alerts-check" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/28-powercenter-down-alerts-check/*.md app/Adocs/2026-10-05/28-powercenter-down-alerts-check/*.txt app/Adocs/2026-10-05/28-powercenter-down-alerts-check/*.tf app/Adocs/2026-10-05/28-powercenter-down-alerts-check/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: PowerCenter down alerts as one Dynatrace detector"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
