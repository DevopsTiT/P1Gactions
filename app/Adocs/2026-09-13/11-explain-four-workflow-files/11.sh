ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json"
wc -l "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json/"*.yaml "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json/"*.json
rg -n "^(  )?(title|onProblemClose|tasks:|prepare-payload|create-servicenow|create-pagerduty|cross-link|resolve-snow)" "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json/ago-problem-to-snow-pagerduty.workflow-template.yaml"
rg -n "^(  )?(title|onProblemClose|tasks:|resolve-snow)" "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json/ago-problem-closed-resolve-snow-pd.workflow-template.yaml"
echo "Upload create once + close once; YAML or JSON per workflow; replace __SNOW_*__ and __PD_ROUTING_KEY__"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-13/11-explain-four-workflow-files"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: explain SNOW PD open and close workflow files"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
