nl -ba "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-28/4-open-close-enriched-parallel/1-open-silva-http-and-pagerduty-enriched.workflow.yaml"
nl -ba "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-28/4-open-close-enriched-parallel/2-close-silva-http-and-pagerduty-enriched.workflow.yaml"
rg -n "^    [a-z-]+:$" "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-28/4-open-close-enriched-parallel/"
rg -n "predecessors|conditions|custom:|else:" "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-28/4-open-close-enriched-parallel/"
rg -n "correlationId|dedupKey|dedup_key|correlation_id" "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-28/4-open-close-enriched-parallel/"
rg -n "__[A-Z_]+__" "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-28/4-open-close-enriched-parallel/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-09-28/5-open-close-yaml-line-by-line
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: line-by-line explanation of enriched open and close workflows"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
