rg -n "__SNOW_|__PD_" "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json/ago-problem-to-snow-pagerduty.workflow-template.yaml"
rg -n "__SNOW_|__PD_" "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json/ago-problem-closed-resolve-snow-pd.workflow-template.yaml"
echo "After you replace: those rg commands should print nothing (or only comments)"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-13/20-how-to-replace-placeholders"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: how to replace SNOW PD workflow placeholders"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
