cd "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01"
sed -n '1,51p' 36-standard-flow-preview-then-post/36-standard-flow-preview-then-post.workflow.yaml
sed -n '53,310p' 36-standard-flow-preview-then-post/36-standard-flow-preview-then-post.workflow.yaml
sed -n '312,763p' 36-standard-flow-preview-then-post/36-standard-flow-preview-then-post.workflow.yaml
sed -n '765,922p' 36-standard-flow-preview-then-post/36-standard-flow-preview-then-post.workflow.yaml
sed -n '924,1031p' 36-standard-flow-preview-then-post/36-standard-flow-preview-then-post.workflow.yaml
sed -n '1033,1078p' 36-standard-flow-preview-then-post/36-standard-flow-preview-then-post.workflow.yaml
sed -n '1080,1180p' 36-standard-flow-preview-then-post/36-standard-flow-preview-then-post.workflow.yaml
sed -n '1182,1248p' 36-standard-flow-preview-then-post/36-standard-flow-preview-then-post.workflow.yaml
sed -n '1,58p' 45-close-direct-v5-trigger-closed/45-close-direct-v5-trigger-closed.workflow.yaml
sed -n '60,150p' 45-close-direct-v5-trigger-closed/45-close-direct-v5-trigger-closed.workflow.yaml
sed -n '152,364p' 45-close-direct-v5-trigger-closed/45-close-direct-v5-trigger-closed.workflow.yaml
sed -n '366,426p' 45-close-direct-v5-trigger-closed/45-close-direct-v5-trigger-closed.workflow.yaml
rg -n "correlation_id|dedup_key" 36-standard-flow-preview-then-post/36-standard-flow-preview-then-post.workflow.yaml 45-close-direct-v5-trigger-closed/45-close-direct-v5-trigger-closed.workflow.yaml
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/46-open-close-workflows-line-by-line" "/Users/k/Work/AIProjects/Files/2026-10-01/"
cp -R "/Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-10-01/46-open-close-workflows-line-by-line" "/Users/k/Codes/Pra/P1GithubActions/P1Gactions/app/Adocs/2026-10-01/"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git add app/Adocs/2026-10-01/46-open-close-workflows-line-by-line
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git commit -m "docs: open and close workflows line by line"
cd /Users/k/Codes/Pra/P1GithubActions/P1Gactions && git push
