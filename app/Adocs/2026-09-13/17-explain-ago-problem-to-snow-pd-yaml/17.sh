python3 -c "import yaml; p='/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-13/4-snow-pd-workflow-yaml-and-json/ago-problem-to-snow-pagerduty.workflow-template.yaml'; d=yaml.safe_load(open(p)); w=d['workflow']; print(w['title']); print(list(w['tasks'])); print('onProblemClose', w['trigger']['eventTrigger']['triggerConfiguration']['onProblemClose']); print(d['dependencies'])"
echo "Edit placeholders in YAML, Upload as template, also import close YAML"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-13/17-explain-ago-problem-to-snow-pd-yaml"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: explain ago-problem-to-snow-pagerduty workflow YAML"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
