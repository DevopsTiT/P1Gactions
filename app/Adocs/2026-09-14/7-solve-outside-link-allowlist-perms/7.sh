echo "1) Dynatrace Settings → External requests → add silvastg.service-now.com → Save"
echo "2) Add events.pagerduty.com too"
echo "3) If no permission to edit allowlist → ask Dynatrace admin"
echo "4) Share Connection ServiceNowTest + add Davesh to workflow draft"
echo "5) Reopen create-servicenow-incident → set Assignment group → test"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-14/7-solve-outside-link-allowlist-perms"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: solve SNOW outside link allowlist and permissions"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
