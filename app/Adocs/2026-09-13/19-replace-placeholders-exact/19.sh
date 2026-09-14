rg -n "__[A-Z0-9_]+__|confluence\.example" "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json"
echo "After edit: rg should show no real leftover placeholders in scripts"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-13/19-replace-placeholders-exact"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: exact placeholder replace list for SNOW PD workflows"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
