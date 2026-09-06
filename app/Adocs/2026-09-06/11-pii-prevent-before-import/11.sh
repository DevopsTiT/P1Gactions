# Optional reminders — review then run yourself (do not auto-apply to prod)
ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-06/11-pii-prevent-before-import/pii-keys-blocklist.txt"
ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-06/11-pii-prevent-before-import/11-oneagent-pii-regex-waves.txt"
ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-06/11-pii-prevent-before-import/11-openpipeline-pii-rules.yaml"
ls "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-06/11-pii-prevent-before-import/pii-scan.dql"
echo "UI: Settings > Collect and capture > Log monitoring > Configure log module > Sensitive data masking"
echo "UI: OpenPipeline > Logs > fieldsRemove + content mask for blocklist keys"
echo "Test with fake JSON only; then run pii-scan.dql after real import starts"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" status
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-06/11-pii-prevent-before-import"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: PII prevent gates before log import"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
