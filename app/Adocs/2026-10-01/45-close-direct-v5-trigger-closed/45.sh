cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/45-close-direct-v5-trigger-closed"
ruby -ryaml -e 'p YAML.load_file("45-close-direct-v5-trigger-closed.workflow.yaml")["workflow"]["trigger"]'
ruby -ryaml -e 'y=YAML.load_file("45-close-direct-v5-trigger-closed.workflow.yaml"); y["workflow"]["tasks"].each{|k,t| File.write("/tmp/c45_#{k}.mjs", t["input"]["script"])}'
node --check /tmp/c45_prepare-close.mjs
node --check /tmp/c45_close-silva-incident.mjs
node --check /tmp/c45_close-pagerduty.mjs
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/45-close-direct-v5-trigger-closed" "/Users/k/Work/AIProjects/Files/2026-10-01/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/45-close-direct-v5-trigger-closed" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-01/"
# Do NOT commit *.workflow.yaml (contains secrets). Docs only:
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-01/45-close-direct-v5-trigger-closed/*.md app/Adocs/2026-10-01/45-close-direct-v5-trigger-closed/*.txt
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: close workflow v5 trigger closed only"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
