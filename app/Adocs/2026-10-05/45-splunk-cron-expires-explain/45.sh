echo 'Splunk search: index=_internal sourcetype=scheduler savedsearch_name="Datalake_Batch Result" | table _time scheduled_time status result_count'
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/45-splunk-cron-expires-explain" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/45-splunk-cron-expires-explain" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/45-splunk-cron-expires-explain/*.md app/Adocs/2026-10-05/45-splunk-cron-expires-explain/*.txt
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: explain Splunk cron and expires vs Dynatrace"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
