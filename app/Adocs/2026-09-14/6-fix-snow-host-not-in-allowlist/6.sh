echo "Fix: add silvastg.service-now.com to Dynatrace External requests / outbound allowlist"
echo "Also add events.pagerduty.com for PagerDuty"
echo "Then reopen create-servicenow-incident and set Assignment group"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-14/6-fix-snow-host-not-in-allowlist"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: fix ServiceNow host not in Dynatrace allowlist"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
