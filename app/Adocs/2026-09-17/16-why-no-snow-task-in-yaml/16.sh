echo "No snow task in YAML is correct when using Problem notification servicenowstg"
echo "Use seq 15 PD-only YAML; or seq 13 Connection YAML with ITSM OFF"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-17/16-why-no-snow-task-in-yaml"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: explain why Problem notification has no snow workflow task"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
