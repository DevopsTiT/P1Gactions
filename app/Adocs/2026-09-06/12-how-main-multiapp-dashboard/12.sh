# Review then run yourself — do not auto-change Dynatrace tenant
ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-06/12-how-main-multiapp-dashboard/Main-MultiApp-Health-Dashboards.json"
open "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-06/12-how-main-multiapp-dashboard/Main-MultiApp-Health-Dashboards.json"
echo "Dynatrace: Dashboards > Create/Import > paste Main-MultiApp-Health-Dashboards.json"
echo "Tag hosts/services: app:eip app:api app:payment"
echo "Use variable app=All or app=EIP on the SAME board"
echo "Do NOT create separate EIP/API/Payment dashboards"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" status
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-06/12-how-main-multiapp-dashboard"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: how to build main multi-app Dynatrace dashboard"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
