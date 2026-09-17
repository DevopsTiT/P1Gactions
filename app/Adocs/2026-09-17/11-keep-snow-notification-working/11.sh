echo "Settings → Problem notifications → servicenowstg → keep ON"
echo "ITOM ON; ITSM OFF (unless you want classic INC)"
echo "External requests → silvastg.service-now.com"
echo "Do not delete notification when adding PD workflows"
echo "Test Problem → check SNOW ITOM event"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-17/11-keep-snow-notification-working"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: how to keep classic ServiceNow problem notification"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
