cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/31-controlm-alerts-full-inventory-v2"
terraform init
terraform validate
terraform plan
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/31-controlm-alerts-full-inventory-v2" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/31-controlm-alerts-full-inventory-v2" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/31-controlm-alerts-full-inventory-v2/*.md app/Adocs/2026-10-05/31-controlm-alerts-full-inventory-v2/*.txt app/Adocs/2026-10-05/31-controlm-alerts-full-inventory-v2/*.tf app/Adocs/2026-10-05/31-controlm-alerts-full-inventory-v2/*.dql
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: Control-M alerts full inventory v2"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
