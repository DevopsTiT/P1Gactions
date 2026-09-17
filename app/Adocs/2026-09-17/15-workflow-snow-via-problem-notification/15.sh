echo "Upload: 1-open-pd-snow-via-notification.workflow.yaml"
echo "Upload: 2-close-pd-snow-via-notification.workflow.yaml"
echo "Keep servicenowstg ITSM ON + ITOM ON; do not add snow-create-incident"
echo "Folder: /Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-17/15-workflow-snow-via-problem-notification"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-17/15-workflow-snow-via-problem-notification"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: workflow YAML using Problem notification for SNOW instead of Connection create"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
