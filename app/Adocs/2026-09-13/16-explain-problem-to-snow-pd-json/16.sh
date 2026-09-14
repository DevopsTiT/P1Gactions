python3 -c "import json; p='/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json/problem-to-snow-pagerduty.workflow.json'; w=json.load(open(p)); print(w['title']); print(list(w['tasks'])); print('onProblemClose', w['trigger']['eventTrigger']['triggerConfiguration']['onProblemClose'])"
echo "Replace __SNOW_*__ and __PD_ROUTING_KEY__ before upload"
echo "Also upload problem-closed-resolve-snow-pd.workflow.json for close"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-13/16-explain-problem-to-snow-pd-json"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: explain problem-to-snow-pagerduty workflow JSON"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
