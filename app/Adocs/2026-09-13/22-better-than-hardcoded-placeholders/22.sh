echo "Prefer: Dynatrace ServiceNow Connection instead of __SNOW_USER__/__SNOW_PASSWORD__ in script"
echo "Prefer: PD routing key in secret or UI-after-import — not in git"
echo "OK in Git: assignMap sys_ids, runbook URLs, severity rules"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-13/22-better-than-hardcoded-placeholders"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: better alternatives to hardcoded workflow placeholders"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
