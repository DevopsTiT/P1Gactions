ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-14/3-snow-pd-workflow-with-connection/"*connection*
echo "Re-upload fixed YAML; map Connection ServiceNowTest"
echo "Add https://silvastg.service-now.com to External Requests"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-14/3-snow-pd-workflow-with-connection" "app/Adocs/2026-09-14/5-fix-upload-schema-error"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "fix: Dynatrace workflow upload schema for SNOW Connection pack"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
