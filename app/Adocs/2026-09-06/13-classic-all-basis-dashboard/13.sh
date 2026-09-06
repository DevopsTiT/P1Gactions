# Review then run yourself
ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-06/13-classic-all-basis-dashboard/Main-MultiApp-Health-Classic.json"
ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-06/13-classic-all-basis-dashboard/13-request-count-tile-template.json"
open "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-06/13-classic-all-basis-dashboard/Main-MultiApp-Health-Classic.json"
echo "Import Classic: Dynatrace Dashboards Classic > Upload Main-MultiApp-Health-Classic.json"
echo "All = empty filterBy; EIP = Dashboard filter tag app:eip on SAME board"
echo "Do NOT create separate EIP Classic dashboard"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" status
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-06/13-classic-all-basis-dashboard" "app/Adocs/Tasks/Dashboard/Main-MultiApp"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: Classic All-basis main multi-app dashboard JSON"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
