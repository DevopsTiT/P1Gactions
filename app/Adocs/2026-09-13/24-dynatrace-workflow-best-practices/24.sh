echo "Workflow best practise: one job, filter triggers, secrets outside Git, stable keys, test open+close"
echo "SNOW+PD: two workflows; Connection for SNOW; same correlation_id/dedup_key family"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-13/24-dynatrace-workflow-best-practices"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: Dynatrace workflow best practices for SNOW PD"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
