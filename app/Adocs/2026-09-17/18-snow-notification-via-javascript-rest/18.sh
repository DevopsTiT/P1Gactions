echo "Upload OPEN: /Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-17/18-snow-notification-via-javascript-rest/1-open-snow-js-rest-and-pd.workflow.yaml"
echo "Upload CLOSE: /Users/k/Learnings/AIProject/CursorFiles/Daily Files/2026-09-17/18-snow-notification-via-javascript-rest/2-close-snow-js-rest-and-pd.workflow.yaml"
echo "Replace __SNOW_PASSWORD__ and __PD_ROUTING_KEY__; allowlist silvastg.service-now.com; disable classic ITSM/ITOM to avoid duplicates"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" add "app/Adocs/2026-09-17/18-snow-notification-via-javascript-rest"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" commit -m "docs: ServiceNow notification-like REST via workflow run-javascript"
git -C "/Users/k/Codes/Pra/P1GithubActions/P1Gactions" push
