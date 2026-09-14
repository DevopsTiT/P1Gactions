echo "Diagram meaning: Problem open creates INC+PD; Problem close resolves both via shared Problem ID"
echo "correlation_id = Problem ID on ServiceNow"
echo "dedup_key = dt-problem-<ProblemID> on PagerDuty"
echo "Watch: Dynatrace Executions + ServiceNow + PagerDuty"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-13/14-explain-demo-flow-plain-english"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: plain English explain SNOW PD demo flow"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
