mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/46-splunk-8am-24h-to-dynatrace" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/46-splunk-8am-24h-to-dynatrace" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/46-splunk-8am-24h-to-dynatrace/*.md app/Adocs/2026-10-05/46-splunk-8am-24h-to-dynatrace/*.txt
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: Splunk 08:00 cron and 24h expires vs Dynatrace detector"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
