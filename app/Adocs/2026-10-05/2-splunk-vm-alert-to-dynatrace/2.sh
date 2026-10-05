eventcreate /T ERROR /ID 258 /L APPLICATION /SO DTAlertTest /D "Dynatrace alert test eventID 258"
mkdir -p "/Users/k/Work/AIProjects/Files/2026-10-05" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/2-splunk-vm-alert-to-dynatrace" "/Users/k/Work/AIProjects/Files/2026-10-05/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-05/2-splunk-vm-alert-to-dynatrace" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-05/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-05/2-splunk-vm-alert-to-dynatrace/*.md app/Adocs/2026-10-05/2-splunk-vm-alert-to-dynatrace/*.txt
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: Splunk VM eventID 258 alert converted to Dynatrace"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
